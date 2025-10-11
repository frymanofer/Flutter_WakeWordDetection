# Flutter_WakeWordDetection

[![GitHub release](https://img.shields.io/github/release/frymanofer/KeyWordDetectionIOSFramework.svg)](https://github.com/frymanofer/KeyWordDetectionIOSFramework/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

By [DaVoice.io](https://davoice.io)

[![Twitter URL](https://img.shields.io/twitter/url?style=social&url=https%3A%2F%2Ftwitter.com%2FDaVoiceAI)](https://twitter.com/DaVoiceAI)


Welcome to **Davoice WakeWord / Keywords Detection** – Wake words and keyword detection solution designed by **DaVoice.io**.

## About this project

This is a **"wake word"** package for **"Flutter"**. A wake word is a keyword that activates your device, like "Hey Siri" or "OK Google". "Wake Word" is also known as "keyword detection", "Phrase Recognition", "Phrase Spotting", “Voice triggered”, “hotword”, “trigger word”

It also provide **Speech to Intent**. **Speech to Intent** refers to the ability to recognize a spoken word or phrase
and directly associate it with a specific action or operation within an application. Unlike a **"wake word"**, which typically serves to activate or wake up the application,
Speech to Intent goes further by enabling complex interactions and functionalities based on the recognized intent behind the speech.

For example, a wake word like "Hey App" might activate the application, while Speech
to Intent could process a phrase like "Play my favorite song" or "Order a coffee" to
execute corresponding tasks within the app.
Speech to Intent is often triggered after a wake word activates the app, making it a key
component of more advanced voice-controlled applications. This layered approach allows for
seamless and intuitive voice-driven user experiences.

## News.

Just released flutter_wake_word version 13 which includes **optimized Android wake word with 1.2% battery usage per hour!!**

## Flutter wake word detection.

Add "flutter_wake_word" pub to your pubspec.yaml file as in the example folder.

Add the below if you want always the latest version or specify a version:

pubspec.yaml:
```
dependencies:
.....

  flutter_wake_word:
    # Use the latest version.
```

link: https://pub.dev/packages/flutter_wake_word

If you need supoort contact us at: info@davoice.io

## Features

- **High Accuracy:** We have succesfully reached over 99% accurary for all our models. **Here is one of our customer's benchmarks**:

```
** Benmark used recordings with 1326 TP files.
** Second best was on of the industry top players who detected 1160 TP 
** Third  detected TP 831 out of 1326

MODEL         DETECTION RATE
===========================
DaVoice        0.992458
Top Player     0.874811
Third          0.626697
```

- **Easy to deploy with Flutter:** Check out our example. With a few simple lines of code, you have your own keyword detecting enabled app.
- **Low Latency:** Experience near-instantaneous keyword detection.

## Platforms and Supported Languages

- **Wake word for Android and IOS:** Flutter for both IOS and Android.

# Android

🛠️ Android Changes Required due to optimized battery usage - adding libc++_shared.so

Flutter does not include libc++_shared.so by default therefore I added them to the example application.

If your app does not have these libraries you that depend on C++, you must also manually add this shared library to your Android app.

✅ Step 1: Modify example/android/app/build.gradle

```
android {
    namespace = "com.example.flutter_wake_word_example"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    sourceSets {
        main {
            jniLibs.srcDirs = ['src/main/jniLibs'] // Ensure JNI libraries are included
        }
    }

    // 1) Add packagingOptions
    packagingOptions {
        // Avoid duplicate-file errors and ensure libc++_shared.so is included
        pickFirst "lib/armeabi-v7a/libc++_shared.so"
        pickFirst "lib/arm64-v8a/libc++_shared.so"
        pickFirst "lib/x86/libc++_shared.so"
        pickFirst "lib/x86_64/libc++_shared.so"
        pickFirst '**/libc++_shared.so' // Ensures it's included in case of conflicts
    }
}
```

✅ Step 2: Add libc++_shared.so to Your App

Manually place the libc++_shared.so file in the correct directories:

```
example/android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so
example/android/app/src/main/jniLibs/armeabi-v7a/libc++_shared.so
example/android/app/src/main/jniLibs/x86/libc++_shared.so
example/android/app/src/main/jniLibs/x86_64/libc++_shared.so
```

✅ Step 3: Modify example/android/build.gradle

Ensure that your example/android/build.gradle includes the following repository paths:

```
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url "${project.projectDir}/libs" } // Plugin's local libs directory
	    maven { url "${project(":flutter_wake_word").projectDir}/libs" }
        maven { url("${project(':flutter_wake_word').projectDir}/libs") } 
        maven {
            url("${project(':flutter_wake_word').projectDir}/libs")
        }
        mavenLocal()
    }
}
```

# Wake word generator

## Create your "custom wake word""

In order to generate your custom wake word you will need to:

- **Create wake word mode:**
    Contact us at info@davoice.io with a list of your desired **"custom wake words"**.

    We will send you corresponding models typically your **wake word phrase .onnx** for example:

    A wake word ***"hey sky"** will correspond to **hey_sky.onnx**.

- **Add wake words to Android:**
    Simply copy the new onnx files to:

    android/app/src/main/assets/*.onnx

- **Add Wake word to IOS**
    Copy new models somewhere under ios/YourProjectName.

    You can create a folder ios/YourProjectName/models/ and copy there there.

    Now add each onnx file to xcode making sure you opt-in “copy if needed”.

- **In Dart code add the new onnx files to your configuration**
  
    Change:

```
  final List<InstanceConfig> instanceConfigs = [
    InstanceConfig(
      id: 'need_help_now',
      modelName: 'need_help_now.onnx',
      threshold: 0.9999,
      bufferCnt: 3,
      sticky: false,
    ),
  ];
```

To your generated custom wake word, for example if you wake word is "hey sky":

```
  final List<InstanceConfig> instanceConfigs = [
    InstanceConfig(
      id: 'hey_sky',
      modelName: 'hey_sky.onnx',
      threshold: 0.9999,
      bufferCnt: 3,
      sticky: false,
    ),
  ];

```

- **Last step - Rebuild your project**

## Contact

For any questions, requirements, or more support for Flutter, please contact us at info@davoice.io.

## Installation and Usage

## Benchmark.

Our customers have benchmarked our technology against leading solutions, including Picovoice Porcupine, Snowboy, Pocketsphinx, Sensory, and others. 
In several tests, our performance was comparable to Picovoice Porcupine, occasionally surpassing it, however both technologies consistently outperformed all others in specific benchmarks. 
For detailed references or specific benchmark results, please contact us at ofer@davoice.io.

## Activating Microphone while the app operates in the background or during shutdown/closure.
This example in the Git repository enables Android functionality in both the foreground and background, and iOS functionality in the foreground. However, we have developed an advanced SDK that allows the microphone to be activated from a complete shutdown state on Android and from the background state on iOS. If you require this capability for your app, please reach out to us at ofer@davoice.io.

### Key words

DaVoice.io Voice commands / Wake words / Voice to Intent / keyword detection npm for Android and IOS.
"Wake word detection github"
"Wake Word" 
"keyword detection"
"Phrase Recognition"
"Phrase Spotting"
“Voice triggered”
“hotword”
“trigger word”
"Flutter wake word",
"Wake word detection github",
"Wake word generator",
"Custom wake word",
"voice commands",
"wake word",
"wakeword",
"wake words",
"keyword detection",
"keyword spotting",
"speech to intent",
"voice to intent",
"phrase spotting",
"react native wake word",
"Davoice.io wake word",
"Davoice wake word",
"Davoice react native wake word",
"Davoice Flutter wake word",
"wake",
"word",
"Voice Commands Recognition",
"lightweight Voice Commands Recognition",
"customized lightweight Voice Commands Recognition",
"rn wake word"

## Links

- **Wake word pub package:** https://pub.dev/packages/flutter_wake_word

Here are wakeword detection GitHub links per platform:

- **For Python:** https://github.com/frymanofer/Python_WakeWordDetection
- **Web / JS / Angular / React:** https://github.com/frymanofer/Web_WakeWordDetection/tree/main
- **For React Native:** [ReactNative_WakeWordDetection](https://github.com/frymanofer/ReactNative_WakeWordDetection)
- **For Flutter:** [https://github.com/frymanofer/Flutter_WakeWordDetection]
- **For Android:** [KeywordsDetectionAndroidLibrary](https://github.com/frymanofer/KeywordsDetectionAndroidLibrary)
- **For iOS framework:** 
  - With React Native bridge: [KeyWordDetectionIOSFramework](https://github.com/frymanofer/KeyWordDetectionIOSFramework)
  - Sole Framework: [KeyWordDetection](https://github.com/frymanofer/KeyWordDetection)
 
  
