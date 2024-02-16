import argparse
from pathlib import Path
import requests

# Only language over that percentage of translation will be downloaded.
MIN_PROGRESS_PERCENTAGE = 80

def update_locales(api_key: str, path: Path, format: str) -> None:

    if not path.exists():
        path.mkdir(parents=True, exist_ok=True)

    session = requests.Session()
    # Set up authentication for all requests
    session.auth = (api_key, '')

    # Getting available locales for the project
    locales = session.get('https://localise.biz/api/locales').json()
    for locale in locales:
        num_translated = locale['progress']['translated']
        num_untranslated = locale['progress']['untranslated']
        if 100 * num_translated / (num_translated + num_untranslated) <= MIN_PROGRESS_PERCENTAGE:
            continue

        locale_code = locale['code'].replace("-", "_")
        file_name = f"{locale_code}.{format}"
        file_path = path / file_name

        response = session.get(f'https://localise.biz/api/export/locale/{file_name}')

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
    parser.add_argument('--format', help='File format for locale files', type=str, default='json')
    args = parser.parse_args()

    update_locales(api_key=args.api_key, path=args.path, format=args.format)
