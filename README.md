# **Mosquito Alert** 
## What is Mosquito Alert?
Mosquito Alert is a mobile phone application that is part of a larger citizen science system bringing together ordinary people, scientists and public health officials to fight against mosquitoes that can transmit diseases like Zika, dengue and chikungunya. More information about the project can be found at http://www.mosquitoalert.com.

![Mosquito_Alert](https://user-images.githubusercontent.com/30580652/162627346-7018489f-7525-40ca-a3f6-b0dd59b519f3.png)

## How to compile the app
1. Clone the repository to your local machine
2. Go to android/local.properties and at the end of the file add the following lines: (If the file doesn't exist, just create it yourself)
```
# By leaving the values empty, the app will compile successfully but packages using this license will display an error (this is ok!)
googlemaps.Key=
```
3. Run the following commands, one by one
```
flutter channel stable
flutter pub get
flutter upgrade
```
4. Connect your device or emulator and run the command ```flutter run```
5. That's all! If you have problems, don't hesitate to open an issue on [Github Issues](https://github.com/Mosquito-Alert/Mosquito-Alert-Mobile-App/issues) and we'll be happy to help you!

## How to contribute
Do you want to contribute?

Feel free to fork our repository, create a new branch, make your changes and submit a pull request. We'll review it as soon as possible and merge it.

It would be awesome if you assign yourself to an existing task or you open a new issue in [Github Issues](https://github.com/Mosquito-Alert/Mosquito-Alert-Mobile-App/issues), to keep other contributors informed on what you're working on.

If this project is useful for you, please consider starring this repository and giving us 5 stars on the app stores to give us more visibility.

## Features
* Report mosquito bite.
* Report mosquito sighting.
* Report breeding site.
* See your data in a map.
* Scoreboard of the contributors.
* Mosquito guide to learn.
* Free, open source software. You'll never have to pay anything or watch any ad to use it.

## Download the app
For more information, please visit the project [website](http://www.mosquitoalert.com/en/). 

- [Google Play (Android)](https://play.google.com/store/apps/details?id=ceab.movelab.tigatrapp).
- [Apple Store (iOS)](https://itunes.apple.com/app/id890635644)

## License
Mosquito Alert is free software: it can be redistributed and/or modified under the terms of the GNU General Public License published by the Free Software Foundation (license version 3 or higher).
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

If you want to see the license in more detail, there are two options.
- Open the app from your phone > Settings > Mosquito Alert License
- See [the license file in english](https://github.com/Mosquito-Alert/Mosquito-Alert-Mobile-App/blob/master/assets/html/license_en.html) or see [the translated license into multiple other languages](https://github.com/Mosquito-Alert/Mosquito-Alert-Mobile-App/blob/master/assets/html)

