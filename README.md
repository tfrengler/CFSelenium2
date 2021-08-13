# CFSelenium2

A simple Coldfusion wrapper for Selenium, designed to get you quickly up and running, with a minimum of fuss.

This might be for you if:
1. You are a beginner, and/or aren't super technical, and just need to get Selenium up and running.
1. You don't know (or care) much about how Selenium is started or how to get the webdrivers going.
1. You don't want to do the boilerplate code yourself, and your plan for Selenium doesn't rely on highly specialized or advanced management of Selenium and the webdrivers.
1. You really don't mind not having 100% control over how Selenium instantiation works or how the webdrivers are managed.

**A bit of background...**

My name is Thomas and I'm a fairly experienced automation tester who has created half a dozen frameworks (often from scratch) powered by Selenium for a variety of browser-based projects. I was getting tired of repeatedly writing the same boilerplate code for Selenium over and over again. Since I have personally never worked on a project that required more than "have the automation tests interact with one or two browser types" I decided to make a library for myself that I could reuse, and thought that perhaps it might be useful for someone else.

**So what does it do?**
- Abstracts away getting an instance of RemoteWebDriver, which is the primary interface for interacting with the browser.
- Abstracts away the finer details of starting and stopping the webdriver executables for a given browser. The webdriver manager uses the DriverService-classes under the hood.
- Aside from hiding the finer details of the instantiation, you get full access to the RemoteWebDriver via the wrapper.
- Supports both local and remote webdriver usage. Both of these "modes" are achieved purely via the RemoteWebDriver-class. I specially chose not to use the local browser-driver classes to keep things simple.
- Offers support for Chrome, Firefox, Edge and IE. Anything else and you'll have to write your own implementation, sorry.

**Known issues**

Firefox on Linux may throw an error related to profiles (cannot be loaded or is inaccessible). It seems to have something to do with the profile.ini file being in the snap/mozilla/... folder but selenium tries to find it in the local/bin or usr/bin folders. I haven't been able to find a fix for this yet.

**Disclaimers**
- Constructive feedback is always welcome, though keep in mind this library was written by me, primarily for use by me, and thus it adheres very much to my principles of software architecture.
- This library is provided "as is". I have no roadmap for future features, and bugs will only be fixed when or if I have time for it.

## Compatibility/requirements

1. Selenium **v3.141** (https://selenium-release.storage.googleapis.com/index.html?path=3.141/) IMPORTANT: download **selenium-java-3.141.0.zip**, and not any of the server-files!
2. **Lucee 5.3** or **Adobe Coldfusion 2018**

## Installation

Things you need to download/install:
1. Selenium's Java bindings: download the zip (see link above). How you make these available to Lucee/ACF is _your_ responsibility (and there are multiple options). This is where the **JavaObjectFactory** comes in. More about that later.
2. NOTE: The zip-file contains 2 jar-files and a sub-folder called **libs**. It's advised to take all the jar-files (except -sources.jar) and put them into a single folder (so no jars in subfolders). Otherwise - depending on how you load the jars of course - you may get issues with Coldfusion not being able to find and instantiate certain classes or call certain methods.
3. The webdrivers you want: these are maintained by the various browser vendors (except the IE-driver, which is maintained by Selenium). Download these, extract them to a shared folder somewhere where they are readable (and executable, on Linux). NOTE: You can also use the framework to manage the webdriver files for you. See the section **Webdriver binary download tool** further down.

## Getting started

Outside of the JavaObjectFactory, are two principal classes to work with: **SeleniumWrapper** and **WebdriverManager**. Remember what I said earlier about "local" and "remote" mode? If you are not running the webdriver-executables locally (presumably you are using the Selenium Standalone Server) then you don't have to care about **WebdriverManager**.

Since the library needs to access Selenium's classes it needs to know how to create the Java-objects. This is facilitated by a component called **JavaObjectFactory** which is required by the other two classes:

```coldfusion
<cffunction name="init" returntype="JavaObjectFactory" access="public" hint="Constructor" >
	<cfargument name="javaloaderInstance" type="any" required="false" hint="Instance of Mark Mandel's JavaLoader. If you for some reason pass both arguments, then the Javaloader takes precedence." />
	<cfargument name="jarFolder" type="string" required="false" hint="Full path to folder where all the Java jars are located. Does not work in ACF." />
</cffunction>
```

If you pass no arguments then it just uses **createObject()** to create the Java-classes and assumes you've made Selenium's jar-files available to Lucee/ACF somehow. The object factory is stored internally and can be accessed via the public field **SeleniumWrapper.ObjectFactory**. This is the easiest way for yourself to create the Selenium objects you need to continue working with the webdriver once you have an instance of SeleniumWrapper. You do this by calling Get() on the factory:

```coldfusion
<cffunction name="Get" returntype="any" access="public" hint="Creates and returns a given Java object. The returned object is a static handle, so you still have to call init() on it yourself." >
	<cfargument name="class" type="string" required="true" hint="Name of the Java Java-class you wish to create a handle for" />
</cffunction>
```

Since I guess that most people's basic usage is running the browser and webdriver on the same machine as the tests that's the example we'll go with:

```coldfusion
<!-- Create the object factory, telling it where the Selenium jar-files are -->
<cfset ObjectFactory = new JavaObjectFactory(jarFolder="C:\Temp\selenium-java-3.141.59\") />
<!-- Getting an instance of the webdrivermanager, telling it where the executables are -->
<cfset Webdrivers = new WebdriverManager(ObjectFactory, "C:\Temp\Webdrivers\") />

<!-- Starting chrome's driver, getting the URL the driver runs on, which we pass to SeleniumWrapper -->
<cfset RemoteURL = Webdrivers.Start("CHROME") />
<cfset Selenium = new SeleniumWrapper(ObjectFactory, RemoteURL, "CHROME") />

<!-- Doing a test to see if it all works -->
<cfset By = Selenium.ObjectFactory.Get("org.openqa.selenium.By") />
<cfset Selenium.Webdriver.navigate().to("https://www.selenium.dev/documentation/en/getting_started/") />
<cfset Element = Selenium.Webdriver.FindElement(By.CssSelector("nav##sidebar")) />

<!-- Clean-up. Make sure to dispose both Selenium AND the webdriver (in that order), otherwise you may end up with hanging browser threads -->
<cfset Selenium.Dispose() />
<cfset Webdrivers.Stop("CHROME") />
```

## Webdriver binary download tool

Recently I added functionality that allows the framework to download latest webdriver binaries for you. The main method for doing so is called **GetLatestWebdriverBinary**, and allows you to chose the browser, platform and architecture you want to download for. This method will check if your current version (works even if you have no webdrivers downloaded yet) is lower than the latest available then downloads, and extracts it for you. You could chose to call this method each time before you start a test run for example, to ensure you always have the newest version.

There's another method called **DetermineLatestAvailableVersion** you can use to get latest version as a string to do with as you please, as well as **GetCurrentVersion** which does exactly what it says. Together you could use these to determine yourself whether you need to update, even displaying it on a webpage somewhere.

Whichever option you chose you will ALWAYS incur at least one HTTP call to determine the latest version. The call to get the version times out after 10 seconds, and the call to download the binary times out after 30.

The current version of the webdriver binary is stored in a text-file in the webdriver folder, called **BROWSER_PLATFORM_version.txt**. If this file is not present the current version is considered to be 0 which will cause the newest binary to be downloaded.

You can download and keep webdriver binaries per platform but not per architecture. This is mostly to keep the handling of the files internally for starting and stopping the DriverService simple and stable.

IE11 is not supported mostly because this version follows Selenium's (since the Selenium project makes and maintains the IEDriver) so it's not gonna change often anyway and wasn't worth the trouble implementing.

```coldfusion
    <cffunction access="public" name="GetLatestWebdriverBinary" returntype="string" output="false" hint="Downloads the latest webdriver binary for a given browser and platform if it's newer than the current version (or there is no current version). Returns a string with a text message indicating whether the driver was updated or not." >
        <cfargument name="browser" type="string" required="true" hint="Valid options are: CHROME, FIREFOX or EDGE" />
        <cfargument name="platform" type="string" required="true" hint="Valid options are: WINDOWS or LINUX" />
        <cfargument name="architecture" type="string" required="true" hint="Valid options are: x86 or x64" />
</cffunction>
```

## Technical overview (classes, public methods, properties etc)

It's worth noting that IE is quirky and can be hard to get to cooperate. And it requires more work than simply starting the driver and interfacing with it via Selenium: https://github.com/SeleniumHQ/selenium/wiki/InternetExplorerDriver#required-configuration

---

### final component _SeleniumWrapper_:

The primary interface for interacting with browsers, which you do via the public field **Webdriver**.

**IMPORTANT:** Don't forget to clean up by calling ***SeleniumWrapper.Webdriver.Quit()** or **SeleniumWrapper.Dispose()** when you are done using this instance, otherwise you may have hanging browser instances.

**CONSTRUCTOR:**
```coldfusion
<cffunction name="init" access="public" returntype="SeleniumWrapper" hint="Constructor. Note that whole a lot of arguments are optional, some become required when others are not passed. Basically 'browser' and 'driverOptions' are mutually exclusive, with the latter taking precedence if both are passed" >
    <cfargument name="objectFactory" type="JavaObjectFactory" required="true" hint="An instance of 'JavaObjectFactory', used internally to create the necessary Java-objects" />
    <cfargument name="remoteURL" type="any" required="true" hint="The URL that the browser driver is running on, in the form of an instance of 'java.net.URL'. You get this from WebdriverManager.Start()" />
    <cfargument name="browser" type="string" required="false" default="DEFAULT_INVALID" hint="The browser you want this instance to represent. Mutually exclusive with 'driverOptions'. Will create the corresponding driver options for you, using certain default values (no proxy for all browser, a temp profile for Firefox, normal pageload strategy for Edge, using CreateProcess API to launch IE11)" />
    <cfargument name="browserArguments" type="array" required="false" default=#[]# hint="An array of string arguments to pass to the browser upon startup, such as '--headless' for Chrome for example" />
    <cfargument name="driverOptions" type="any" required="false" hint="An instance of the browser's Selenium DriverOption-class. Mutually exclusive with 'browser' and 'browserArguments'. Use this option to completely customize the browser options yourself, such as proxy, arguments etc" />
</cffunction>
```

**PROPERTIES:**
```coldfusion
this.Webdriver;
this.ObjectFactory;
```

**METHODS**

```coldfusion
<cffunction name="Dispose" access="public" returntype="void" hint="Disposes of this instance of SeleniumWrapper, shutting down any associated browser windows" >
```

---

### final component _WebdriverManager_:

This class is for managing the webdrivers, effectively wrapping Selenium's **DriverService**-classes. It's not entirely for managing the lifecycle since you as the consumer still has to start and stop them via the provided methods. What this class does is hide away the details of how the drivers are managed. All you have to is tell the class on instantiation which folder they live in, and then you can start and stop them yourself. _NOTE:_ **Dispose()** also tries to kill all the webdrivers.

A few things to note. As is hopefully clear this class is meant for the basic use case where the machine that runs the tests (via SeleniumWrapper.Webdriver) also interacts with the browser (via the webdrivers). It also only allows you to start one instance of each driver. It should be noted that a single webdriver executable can easily keep up with communication to half a dozen browsers and Selenium-instances - if you really want (or for some reason need) multiple instances then you need to implement a system for managing the drivers yourself.
Although intended as a singleton there's nothing preventing you from making multiple instances of this and thus starting browser drivers multiple times. I leave that at your discretion.

_NOTE:_ This component should be threadsafe, so calling Start(), Stop(), IsRunning() across threads should be safe as the drivers are stored in structs and those are threaded under the hood (at least Lucee's are...)

**CONSTRUCTORS:**
```coldfusion
<cffunction name="init" access="public" returntype="WebdriverManager" hint="Constructor" >
    <cfargument name="objectFactory" type="JavaObjectFactory" required="true" hint="An instance of 'JavaObjectFactory', used internally to create the necessary Java-objects" />
    <cfargument name="driverFolder" type="string" required="true" hint="Path to the folder wherein the webdriver executables are found" />
</cffunction>
```

_NOTE:_ Don't rename the executables! This library, as well as the internal **DriverService**-class it wraps, expects the original file names (chromedriver, geckodriver etc)

**PROPERTIES:**
* _None_

**METHODS:**

```coldfusion
<cffunction name="Start" access="public" returntype="any" hint="Starts the webdriver for a given browser, and returns the URL it's running on in the form of an instance of 'java.net.URL'" >
    <cfargument name="browser" type="string" required="true" hint="The name of the browser whose webdriver you wish to start" />
    <cfargument name="killExisting" type="boolean" required="false" default="false" hint="If passed as true it will shut down any already running webdrivers. If passed as false (which is the default) and the webdriver is already running, an exception will be thrown" />
    <cfargument name="port" type="numeric" required="false" default="0" hint="The port to start the webdriver on. By default, the webdriver will start on a random, free port on the system" />
</cffunction>
```

```coldfusion
<cffunction name="IsRunning" access="public" returntype="boolean" hint="Check whether the given webdriver is running or not" >
    <cfargument name="browser" type="string" required="true" hint="The name of the browser whose status you want to check" />
</cffunction>
```

```coldfusion
<cffunction name="Stop" access="public" returntype="boolean" hint="Stops a given webdriver, shutting all browser instances associated with it as well" >
    <cfargument name="browser" type="string" required="true" hint="The name of the browser whose webdriver you wish to shut down" />
</cffunction>
```

```coldfusion
<cffunction name="Dispose" access="public" returntype="void" hint="Disposes of this WebdriverManager-instance, releasing all held resources by shutting down all open webdrivers" >
```

## TODO:

Not a guaranteed list, just things I'd like to do one day:
- Port the tools, extensions and locators from my C# Selenium library. Should not be too difficult to pull off, just need the time...
