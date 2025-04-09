import argparse
from pathlib import Path
import requests

from typing import Union, Callable, Dict

def update_locales(asset_id: str, api_key: str, file_prefix: str, path: Union[Path, Callable[[str, str], Path]], lang_filter: Callable[[Dict], bool] = lambda x:True) -> None:
    """
    Update localization files for multiple locales from the Localise.biz API.

    Args:
        api_key (str): The API key for accessing the Localise.biz API.
        path (Union[Path, Callable[[str, str], Path]]): The path where the localization files will be saved.
            This can be either a Path object representing a directory or a callable function
            that takes locale_code (str) and extension (str) as arguments and returns a Path object.
        lang_filter (Callable[[Dict], bool]): A filter function to apply to the retrieved locales.

    Returns:
        None
    """

    session = requests.Session()
    # Set up authentication for all requests
    session.auth = (api_key, '')

    # Getting available locales for the project
    locales = session.get('https://localise.biz/api/locales').json()
    for locale in filter(lang_filter, locales):
        locale_code = locale['code'].replace("-", "_")
        language_code = locale_code.split("_")[0]

        file_name = f"{file_prefix}{language_code}.html"
        if callable(path):
            file_path = path(file_prefix=file_prefix, language_code=language_code)
        else:
            file_path = path / file_name

        # Check if the directory exists, create it
        file_path.parent.mkdir(parents=True, exist_ok=True)

        response = session.get(f'https://localise.biz/api/translations/{asset_id}/{locale['code']}')
        response.raise_for_status()

        translation = response.json()['translation']
        if not translation:
            continue

        with open(file_path, 'wb') as f:
            f.write(response.json()['translation'].encode('utf-8'))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Update locales.')
    parser.add_argument('--api_key', help='API key for localise.biz', required=True)
    parser.add_argument('--path', help='Destination directory for locale files', type=Path, default=Path('./assets/html/'))
    args = parser.parse_args()

    update_locales(
        asset_id='license',
        api_key=args.api_key,
        file_prefix='license_',
        path=args.path,
    )

    update_locales(
        asset_id='privacy',
        api_key=args.api_key,
        file_prefix='privacy_',
        path=args.path,
    )

    update_locales(
        asset_id='terms',
        api_key=args.api_key,
        file_prefix='terms_',
        path=args.path,
    )
