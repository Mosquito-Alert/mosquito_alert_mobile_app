import argparse
from pathlib import Path
import requests

from typing import Union, Callable, Optional, Dict

# Only language over that percentage of translation will be downloaded.
MIN_PROGRESS_PERCENTAGE = 80

# This list ensures certain languages are always included, even if their translation percentage
# is below the MIN_PROGRESS_PERCENTAGE.
# NOTE: fallback=auto will be used. Be sure to configure a custom fallback in localise.biz in
#       case the fallback language is different than the source language.
FORCE_LANGUAGES = ['es_UY']

# Use fallback=auto for the following languages.
# See: https://localise.biz/help/formats/exporting#fallback
#      https://localise.biz/info/notices/20240212
AUTO_FALLBACK = FORCE_LANGUAGES + ['eu_ES', 'ca_ES', 'gl_ES']

def update_locales(api_key: str, path: Union[Path, Callable[[str, str], Path]], extension: str, lang_filter: Callable[[Dict], bool] = lambda x:True, params: dict = {}, tags: list = None) -> None:
    """
    Update localization files for multiple locales from the Localise.biz API.

    Args:
        api_key (str): The API key for accessing the Localise.biz API.
        path (Union[Path, Callable[[str, str], Path]]): The path where the localization files will be saved.
            This can be either a Path object representing a directory or a callable function
            that takes locale_code (str) and extension (str) as arguments and returns a Path object.
        extension (str): The file extension for the localization files (e.g., 'json', 'xml').
        lang_filter (Callable[[Dict], bool]): A filter function to apply to the retrieved locales.
        params (dict, optional): Additional parameters to pass in the API request. Default is an empty dictionary.
        tags (list, optional): Filter by tags.

    Returns:
        None
    """

    session = requests.Session()
    # Set up authentication for all requests
    session.auth = (api_key, '')

    if tags:
        # Check which of the tags passed exist
        available_tags = session.get('https://localise.biz/api/tags').json()

        # Keep only the tags found in both lists (server and input parameter)
        tags = list(
            set(tags).intersection(set(available_tags))
        )

    # Getting available locales for the project
    locales = session.get('https://localise.biz/api/locales').json()
    for locale in filter(lang_filter, locales):
        locale_progress = locale['progress']

        if tags:
            # Get progress taking only into account the tagged assets
            locale_progress = session.get(
                'https://localise.biz/api/locales/{code}/progress'.format(code=locale['code'])
            ).json()['progress']

        num_translated = locale_progress['translated']
        num_untranslated = locale_progress['untranslated']

        locale_code = locale['code'].replace("-", "_")

        is_poorly_translated = 100 * num_translated / (num_translated + num_untranslated) <= MIN_PROGRESS_PERCENTAGE
        if is_poorly_translated and locale_code not in FORCE_LANGUAGES:
            continue

        file_name = f"{locale_code}.{extension}"
        if callable(path):
            file_path = path(locale_code=locale_code, extension=extension)
        else:
            file_path = path / file_name

        # Check if the directory exists, create it
        file_path.parent.mkdir(parents=True, exist_ok=True)

        if locale_code in AUTO_FALLBACK:
            params['fallback'] = 'auto'

        response = session.get(f'https://localise.biz/api/export/locale/{file_name}', params=params)

        if response.status_code == 200:
            with open(file_path, 'wb') as f:
                f.write(response.content)
        elif response.status_code == 304:
            print('Locale', locale['code'], 'is up to date.')
        else:
            response.raise_for_status()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Update locales.')
    parser.add_argument('--api_key', help='API key for localise.biz', required=True)
    parser.add_argument('--path', help='Destination directory for locale files', type=Path, default=Path('./assets/language/'))
    parser.add_argument('--tags', help='Filter assets by comma-separated tag names.', type=lambda x: x.split(','))
    args = parser.parse_args()

    # Update first the general translations
    update_locales(
        api_key=args.api_key,
        path=Path('./assets/language/'),
        extension='json',
        tags=args.tags
    )

    # Update only for iOS plist translations
    ios_plist_kwargs = dict(
        api_key=args.api_key,
        extension='strings',
        params={
            'format': 'plist',
            'filter': 'info-plist',
            'charset': 'utf8'
        },
        tags=args.tags
    )
    # Create InfoPlist.strings in root folder (contain the translation of the app)
    update_locales(
        path=lambda locale_code, extension: Path('./ios/Runner/') / f'InfoPlist.{extension}',
        lang_filter=lambda x: x['code'] == 'en_US',
        **ios_plist_kwargs
    )
    # For each locale, create a new path and add its corresponding InfoPlist.strings.
    update_locales(
        path=lambda locale_code, extension: Path('./ios/Runner/') / f'{locale_code.replace("_", "-")}.lproj' / f'InfoPlist.{extension}',
        **ios_plist_kwargs
    )
