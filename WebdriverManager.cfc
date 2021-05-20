<cfcomponent modifier="final" output="false" hint="Manages the lifecycle of browser webdrivers">

    <!--- PRIVATE --->
    <cfset variables.OS = createObject("java", "java.lang.System").getProperty("os.name").toLowerCase() />
    <cfset variables.IS_WINDOWS = (find("win", variables.OS) GT 0) />
    <cfset variables.IS_MAC = (find("mac", variables.OS) GT 0) />
    <cfset variables.IS_UNIX = (find("nix", variables.OS) GT 0 OR find("nux", variables.OS) GT 0 OR find("aix", variables.OS) GT 0) />
    <cfset variables.IsDisposed = false />

    <cfset variables.ValidBrowsers = ["CHROME","EDGE","FIREFOX","IE11"] />
    <cfset variables.ValidArchitectures = ["x64","x86"] />
    <cfset variables.ValidPlatforms = ["WINDOWS","LINUX"] />
    <cfset variables.DriverNames = {
        "EDGE": "msedgedriver",
        "FIREFOX": "geckodriver",
        "CHROME": "chromedriver",
        "IE11": "IEDriverServer"
    } />

    <cfset variables.DriverServices = {
        "CHROME": 0,
        "EDGE": 0,
        "FIREFOX": 0,
        "IE11": 0
    } />

    <cfset variables.BrowserLatestVersionURLs = {
        "CHROME": "https://chromedriver.storage.googleapis.com/LATEST_RELEASE",
        "FIREFOX": "https://github.com/mozilla/geckodriver/releases/latest",
        "EDGE": "https://msedgewebdriverstorage.blob.core.windows.net/edgewebdriver/LATEST_STABLE"
    } />

    <cfset variables.DriverFolder = 0 />
    <cfset variables.ObjectFactory = 0 />

    <cfset variables.IsValidBrowser = function(required string name) { return arrayFind(variables.ValidBrowsers, arguments.name) GT 0; } />
    <cfset variables.IsValidArchitecture = function(required string name) { return arrayFind(ValidArchitectures, arguments.name) GT 0; } />
    <cfset variables.IsValidPlatform = function(required string name) { return arrayFind(ValidPlatforms, arguments.name) GT 0; } />
    <!--- Remove all dots and alphabetical characters so we can parse the version as a number, otherwise we can't do a proper number comparison --->
    <cfset variables.ParseVersionNumber = function(required string version) { return val(REreplace(arguments.version, "[a-zA-Z|\.]", "", "ALL")); } />
    <cfset variables.GetVersionFileName = function(required string browser, required string platform) { return "#DriverNames[arguments.browser]#_#arguments.platform#_version.txt"; } />

    <cffunction name="init" access="public" returntype="WebdriverManager" hint="Constructor" output="false" >
		<cfargument name="objectFactory" type="JavaObjectFactory" required="true" hint="An instance of 'JavaObjectFactory', used internally to create the necessary Java-objects" />
        <cfargument name="driverFolder" type="string" required="true" hint="Path to the folder wherein the webdriver executables are found" />
        <cfscript>

        if (!directoryExists(arguments.DriverFolder))
            throw(message="Error instantiating WebdriverManager", detail="The folder given in argument 'DriverFolder' does not exist: #arguments.DriverFolder#");

        variables.DriverFolder = arguments.DriverFolder;
        variables.ObjectFactory = arguments.objectFactory;

        </cfscript>
    </cffunction>

    <cffunction name="Start" access="public" returntype="any" hint="Starts the webdriver for a given browser, and returns the URL it's running on in the form of an instance of 'java.net.URL'" output="false" >
        <cfargument name="browser" type="string" required="true" hint="The name of the browser whose webdriver you wish to start" />
        <cfargument name="killExisting" type="boolean" required="false" default="false" hint="If passed as true it will shut down any already running webdrivers. If passed as false (which is the default) and the webdriver is already running, an exception will be thrown" />
        <cfargument name="port" type="numeric" required="false" default="0" hint="The port to start the webdriver on. By default, the webdriver will start on a random, free port on the system" />
        <cfscript>

        if (!variables.IsValidBrowser(arguments.browser))
        {
            Dispose();
            throw(message="Unable to start browser driver", detail="Argument 'browser' (#arguments.browser#) is not a valid value (#arrayToList(variables.ValidBrowsers)#)");
        }

        if (!IS_WINDOWS && (arguments.browser == "IE11" || arguments.browser == "EDGE"))
        {
            Dispose();
            throw(message="Unable to start #arguments.browser#-driver", detail="You are attempting to run the #arguments.browser#-driver on a non-Windows OS: #variables.OS#");
        }

        var DriverName;
        if (IS_WINDOWS)
            DriverName = DriverNames[arguments.browser] & ".exe";
        else
            DriverName = DriverNames[arguments.browser];

        var Service = DriverServices[arguments.browser];

        if (!arguments.killExisting && isObject(Service))
        {
            Dispose();
            throw(message="Unable start #arguments.browser#-driver", detail="It appears to already be running (and argument 'killExisting' is false)");
        }

        if (arguments.killExisting && isObject(Service))
            Stop(arguments.browser);

        var DriverExecutable = createObject("java", "java.io.File").init("#variables.DriverFolder#/#DriverName#");
        if (!DriverExecutable.exists())
            throw(message="Unable start #arguments.browser#-driver", detail="Executable does not exist (#DriverExecutable.getAbsolutePath()#)");

        var ServiceBuilder;
        switch(arguments.browser)
        {
            case "CHROME":
                ServiceBuilder = variables.ObjectFactory.Get("org.openqa.selenium.chrome.ChromeDriverService$Builder").init();
                break;
            case "FIREFOX":
                ServiceBuilder = variables.ObjectFactory.Get("org.openqa.selenium.firefox.GeckoDriverService$Builder").init();
                break;
            case "EDGE":
                ServiceBuilder = variables.ObjectFactory.Get("org.openqa.selenium.edge.EdgeDriverService$Builder").init();
                break;
            case "IE11":
                ServiceBuilder = variables.ObjectFactory.Get("org.openqa.selenium.ie.InternetExplorerDriverService$Builder").init();
                break;
            default:
                Dispose();
                throw("Internal error 101");
        };

        ServiceBuilder.usingDriverExecutable(DriverExecutable);

        if (arguments.port > 0)
            ServiceBuilder.usingPort(arguments.port);
        else
            ServiceBuilder.usingAnyFreePort();

        Service = ServiceBuilder.Build();
        Service.Start();
        DriverServices[arguments.browser] = Service;

        return Service.getUrl();

        </cfscript>
    </cffunction>

    <cffunction name="Stop" access="public" returntype="boolean" hint="Stops a given webdriver, shutting all browser instances associated with it as well" output="false" >
        <cfargument name="browser" type="string" required="true" hint="The name of the browser whose webdriver you wish to shut down" />
        <cfscript>

        if (!variables.IsValidBrowser(arguments.browser))
        {
            Dispose();
            throw(message="Unable to stop browser driver", detail="Argument 'browser' (#arguments.browser#) is not a valid value (#arrayToList(variables.ValidBrowsers)#)");
        }

        var Service = DriverServices[arguments.browser];
        if (!isObject(Service))
            return false;

        Service.stop();
        DriverServices[arguments.browser] = 0;

        return true;
        </cfscript>
    </cffunction>

    <cffunction name="IsRunning" access="public" returntype="boolean" hint="Check whether the given webdriver is running or not" output="false" >
        <cfargument name="browser" type="string" required="true" hint="The name of the browser whose status you want to check" />
        <cfscript>

        if (!variables.IsValidBrowser(arguments.browser))
        {
            Dispose();
            throw(message="Unable to check browser status", detail="Argument 'browser' (#arguments.browser#) is not a valid value (#arrayToList(variables.ValidBrowsers)#)");
        }

        var Service = DriverServices[arguments.browser];
        if (!isObject(Service))
            return false;

        return Service.isRunning();
        </cfscript>
    </cffunction>

    <cffunction name="Dispose" access="public" returntype="void" hint="Disposes of this WebdriverManager-instance, releasing all held resources by shutting down all open webdrivers" output="false" >
        <cfscript>
            if (variables.IsDisposed) return;
            variables.IsDisposed = true;

            for(var BrowserName in variables.DriverServices)
                Stop(BrowserName);
        </cfscript>
    </cffunction>

    <!--- Webdriver download functionality --->
    <cffunction access="public" name="GetLatestWebdriverBinary" returntype="string" output="false" hint="Downloads the latest webdriver binary for a given browser and platform if it's newer than the current version (or there is no current version)" >
        <cfargument name="browser" type="string" required="true" hint="Valid options are: CHROME, FIREFOX or EDGE" />
        <cfargument name="platform" type="string" required="true" hint="Valid options are: WINDOWS or LINUX" />
        <cfargument name="architecture" type="string" required="true" hint="Valid options are: x86 or x64" />
        <cfscript>

            if (!IsValidBrowser(arguments.browser))
                throw(message="Error fetching latest webdriver binary", detail="Argument 'browser' is invalid: #arguments.browser# | Accepted values are: #arrayToList(ValidBrowsers)#");

            if (!IsValidPlatform(arguments.platform))
                throw(message="Error fetching latest webdriver binary", detail="Argument 'platform' is invalid: #arguments.platform# | Accepted values are: #arrayToList(ValidPlatforms)#");

            if (!IsValidArchitecture(arguments.architecture))
                throw(message="Error fetching latest webdriver binary", detail="Argument 'architecture' is invalid: #arguments.architecture# | Accepted values are: #arrayToList(ValidArchitectures)#");

            if (arguments.browser == "EDGE" && arguments.platform == "LINUX")
                throw(message="Error fetching latest webdriver binary", detail="Edge is not available on Linux");

            if (arguments.browser == "CHROME" && arguments.platform == "LINUX" && arguments.architecture == "x86")
                throw(message="Error fetching latest webdriver binary", detail="Chrome on Linux only supports x64");

            if (arguments.browser == "CHROME" && arguments.platform == "WINDOWS" && arguments.architecture == "x64")
                throw(message="Error fetching latest webdriver binary", detail="Chrome on Linux only supports x86");

            if (arguments.browser == "IE11")
                throw(message="Error fetching latest webdriver binary", detail="The IE11 driver is not supported for automatic downloading");

            var VersionFile = "#DriverFolder#/#GetVersionFileName(arguments.browser, arguments.platform)#";
            var CurrentVersion = "0";
            var LatestVersion = DetermineLatestAvailableVersion(arguments.browser);

            if (fileExists(VersionFile))
                CurrentVersion = fileRead(VersionFile);

            if (ParseVersionNumber(CurrentVersion) >= ParseVersionNumber(LatestVersion))
                return "The #arguments.browser#-webdriver is already up to date, not downloading (Current: #CurrentVersion# | Latest: #LatestVersion#)";

            var LatestWebdriverVersionURL = ResolveDownloadURL(LatestVersion, arguments.browser, arguments.platform, arguments.architecture);
            DownloadAndExtract(arguments.browser, arguments.platform, LatestVersion, LatestWebdriverVersionURL);

            return "The #arguments.browser#-webdriver has been updated to the latest version (#LatestVersion#)";
        </cfscript>
    </cffunction>

    <cffunction access="public" name="GetCurrentVersion" returntype="string" output="false" >
        <cfargument name="browser" type="string" required="true" hint="Valid options are: CHROME, FIREFOX or EDGE" />
        <cfargument name="platform" type="string" required="true" hint="Valid options are: WINDOWS or LINUX" />

        <cfscript>
        var VersionFile = "#DriverFolder#/#GetVersionFileName(arguments.browser, arguments.platform)#";
        if (fileExists(VersionFile)) return fileRead(VersionFile);

        return "0";
        </cfscript>
    </cffunction>

    <cffunction access="public" name="DetermineLatestAvailableVersion" returntype="string" output="false" hint="Returns a string representing the latest available version of the webdriver for a given browser" >
        <cfargument name="browser" type="string" required="true" hint="Valid options are: CHROME, FIREFOX or EDGE" />
        <cfscript>

            if (!IsValidBrowser(arguments.browser))
                throw(message="Unable to determine latest available browser version", detail="Argument 'browser' (#arguments.browser#) is not a valid value (#arrayToList(ValidBrowsers)#)");

            var ExpectedStatusCode = (arguments.browser == "FIREFOX" ? 302 : 200);
            var AllowRedirect = arguments.browser != "FIREFOX";

            var HTTPService = new http(url=#BrowserLatestVersionURLs[arguments.browser]#, method="GET", timeout="10", redirect=#AllowRedirect#);
            var LatestVersionResponse = HTTPService.send().getPrefix();

            if (LatestVersionResponse.status_code != ExpectedStatusCode)
            {
                var ErrorMessage = [
                    "URL '#BrowserLatestVersionURLs[arguments.browser]#' returned:",
                    "Status code: #LatestVersionResponse.status_code#",
                    "Status text: #LatestVersionResponse.status_text#",
                    "Error detail: #LatestVersionResponse.errordetail#"
                ];

                throw(message="Error trying to determine latest available webdriver version for #arguments.browser#", detail=arrayToList(ErrorMessage, " | "));
            }

            if (arguments.browser != "FIREFOX")
                return trim(LatestVersionResponse.fileContent);

            // For Firefox we get the redirect URL. Based on that we need to extract the version number from the 'location'-header
            return listLast(LatestVersionResponse.responseheader.location, "/");
        </cfscript>
    </cffunction>

    <cffunction access="private" name="ResolveDownloadURL" returntype="string" output="false" >
        <cfargument name="version" type="string" required="true" hint="" />
        <cfargument name="browser" type="string" required="true" hint="CHROME,FIREFOX" />
        <cfargument name="platform" type="string" required="true" hint="LINUX,WINDOWS" />
        <cfargument name="architecture" type="string" required="false" default="64" hint="x86,x64" />
        <cfscript>

            var PlatformPart = "";
            var ArchitecturePart = "";
            var FileTypePart = "";
            var ReturnData = "";

            switch(arguments.architecture)
            {
                case "x64":
                    ArchitecturePart = "64";
                    break;
                case "x86":
                    ArchitecturePart = "32";
                    break;

                default:
                    throw(message="Error while resolving download URL", detail="Unsupported architecture: #arguments.architecture#");
            }

            switch(arguments.platform)
            {
                case "LINUX":
                    PlatformPart = "linux";
                    FileTypePart = "tar.gz";
                    break;

                case "WINDOWS":
                    PlatformPart = "win";
                    FileTypePart = "zip"
                    break;

                default:
                    throw(message="Error while resolving download URL", detail="Unsupported platform: #arguments.platform#");
            }

            switch(arguments.browser)
            {
                case "FIREFOX":
                    ReturnData = "https://github.com/mozilla/geckodriver/releases/download/#arguments.version#/geckodriver-#arguments.version#-#PlatformPart##ArchitecturePart#.#FileTypePart#";
                    break;

                case "CHROME":
                    ReturnData = "https://chromedriver.storage.googleapis.com/#arguments.version#/chromedriver_#PlatformPart##ArchitecturePart#.zip";
                    break;

                case "EDGE":
                    ReturnData = "https://msedgewebdriverstorage.blob.core.windows.net/edgewebdriver/#arguments.version#/edgedriver_#PlatformPart##ArchitecturePart#.zip";
                    break;

                default:
                    throw(message="Error resolving webdriver download URL", detail="Unsupported browser: #arguments.browser#");
            }

            return ReturnData;
        </cfscript>
    </cffunction>

    <cffunction access="private" name="DownloadAndExtract" returntype="void" output="false" >
        <cfargument name="browser" type="string" required="true" hint="" />
        <cfargument name="platform" type="string" required="true" hint="" />
        <cfargument name="version" type="string" required="true" hint="" />
        <cfargument name="url" type="string" required="true" hint="" />
        <cfscript>

            var DownloadedFileName = listLast(arguments.url, "/");
            var DownloadedPathAndFile = getTempDirectory() & DownloadedFileName;
            var VersionFileName = GetVersionFileName(arguments.browser, arguments.platform);
            var WebdriverFileName = DriverNames[arguments.browser];
            var HTTPService = new http(url=#arguments.url#, method="GET", timeout="10", redirect="true");
            var DownloadReponse = HTTPService.send().getPrefix();

            if (DownloadReponse.status_code != 200)
            {
                var ErrorMessage = [
                    "URL '#arguments.url#' returned:",
                    "Status code: #DownloadReponse.status_code#",
                    "Status text: #DownloadReponse.status_text#",
                    "Error detail: #DownloadReponse.errordetail#"
                ];

                throw(message="Error trying to download latest available webdriver for #arguments.browser#", detail=arrayToList(ErrorMessage, " | "));
            }

            if (arguments.browser == "FIREFOX" && arguments.platform == "LINUX")
            {
                var ExtractedTarFileName = DownloadedFileName.replace(".gz", "");
                if (!ExtractTarGz(DownloadReponse.fileContent, ExtractedTarFileName)) return false;
                if (!ExtractTar(ExtractedTarFileName)) return false;

                // Re-assigning the variable since we don't download the original file to disk
                // This is now the extracted tar-file, and not the tar.gz one
                DownloadedPathAndFile = getTempDirectory() & ExtractedTarFileName;
            }
            else
            {
                // Save the downloaded zip file and extract the contents to the driver-folder
                fileWrite(DownloadedPathAndFile, DownloadReponse.filecontent);
                cfzip(action="unzip", file=#DownloadedPathAndFile#, destination=#DriverFolder#, overwrite="true");
            }

            // (over)Write the version file with the new version and delete the temporary, downloaded zip-file
            fileWrite("#DriverFolder#/#VersionFileName#", arguments.version);

            if (IS_UNIX)
            {
                // Need to set read/write and execute permissions on Linux
                fileSetAccessMode("#DriverFolder#/#WebdriverFileName#", "744");
                fileSetAccessMode("#DriverFolder#/#VersionFileName#", "744");
            }

            // Clean-up, removing the zip-file...
            fileDelete(DownloadedPathAndFile);
            // ...and of course the Edge-zip contains a silly, extra folder and not just the driver binary...
            if (arguments.browser == "EDGE" && directoryExists("#DriverFolder#/Driver_Notes"))
                directoryDelete("#DriverFolder#/Driver_Notes", true);
        </cfscript>
    </cffunction>

    <cffunction access="private" name="ExtractTarGz" returntype="void" output="false" hint="Extracts a TAR-file from a TAR.GZ-archive" >
        <cfargument name="tarAsByteArray" type="binary" required="true" hint="" />
        <cfargument name="outputFileName" type="string" required="true" hint="" />
        <cfscript>
            try
            {
                var InputStream = createObject("java", "java.io.ByteArrayInputStream").init(arguments.tarAsByteArray);
                var GZIPInputStream = createObject("java", "java.util.zip.GZIPInputStream").init(InputStream);
                var OutputStream = createObject("java", "java.io.FileOutputStream").init(getTempDirectory() & arguments.outputFileName);

                var EmptyByteArray = createObject("java", "java.io.ByteArrayOutputStream").init().toByteArray();
                var Buffer = createObject("java","java.lang.reflect.Array").newInstance(EmptyByteArray.getClass().getComponentType(), 1024);
                var Length = GZIPInputStream.read(Buffer);

                while(Length != -1)
                {
                    OutputStream.write(Buffer, 0, Length);
                    Length = GZIPInputStream.read(Buffer);
                }
            }
            catch(any error)
            {
                rethrow;
            }
            finally
            {
                // Release resource handles, otherwise they become locked by Lucee or keep hanging around the heap, using memory
                if (isDefined("OutputStream")) OutputStream.close();
                if (isDefined("GZIPInputStream")) GZIPInputStream.close();
            }
        </cfscript>
    </cffunction>

    <cffunction access="private" name="ExtractTar" returntype="void" output="false" hint="Extracts the first and best file from a TAR-archive. NOTE: This is an incomplete implementation written just for the purpose of this library!" >
        <cfargument name="tarFileName" type="string" required="true" />
        <cfscript>
            // Based on C# code from this source: https://gist.github.com/ForeverZer0/a2cd292bd2f3b5e114956c00bb6e872b
            try
            {
                // Set up the input file as a stream, and prepare the input buffer
                var File = createObject("java", "java.io.File").init(getTempDirectory() & arguments.tarFileName);
                var InputStream = createObject("java", "java.io.FileInputStream").init(File);
                var EmptyByteArray = createObject("java", "java.io.ByteArrayOutputStream").init().toByteArray();
                var InputBuffer = createObject("java","java.lang.reflect.Array").newInstance(EmptyByteArray.getClass().getComponentType(), 100);

                // Read in a 100 bytes, parse it as an ASCII string and discard (remove) all null characters from the string
                // This should give us the file name
                InputStream.read(InputBuffer, 0, 100);
                var Name = createObject("java", "java.lang.String").init(InputBuffer, "US-ASCII");
                Name = REreplace(Name, "[\x0]", "", "ALL");

                if (Name.len() == 0)
                    throw(message="Error extracting file from TAR-archive", detail="Unable to determine name of file in archive");

                // Seek ahead 24 bytes in the stream and read out 12 bytes. Time to find the file size
                InputStream.skip(24);
                InputStream.read(InputBuffer, 0, 12);

                // Pull out the 12 bytes of our buffer we just read in, and parse it as a UTF-8 string
                // Replace all null characters, then parse it as a raw number
                // Lastly, parse as an unsigned 64-bit character using an octal radix
                var ByteSubset = createObject("java", "java.util.Arrays").copyOfRange(InputBuffer, 0, 12);
                var SizeAsString = createObject("java", "java.lang.String").init(ByteSubset, "UTF-8");
                SizeAsString = REreplace(SizeAsString, "[\x0]", "", "ALL");

                if (val(SizeAsString) == 0)
                    throw(message="Error extracting file from TAR-archive", detail="Unable to determine size of file in archive (#Name#)");

                var FinalSize = createObject("java", "java.lang.Long").parseUnsignedLong(val(SizeAsString), 8);
                InputStream.skip(376);

                // Create our output file and output buffer, then read out the amount of bytes equal to our file size and write that to the output file
                var OutputPathAndFileName = "#DriverFolder#/#Name#";
                var OutputStream = createObject("java", "java.io.FileOutputStream").init(OutputPathAndFileName);
                var OutputBuffer = createObject("java","java.lang.reflect.Array").newInstance(EmptyByteArray.getClass().getComponentType(), FinalSize);

                InputStream.read(OutputBuffer, 0, FinalSize);
                OutputStream.write(OutputBuffer);
            }
            catch(any error)
            {
                rethrow;
            }
            finally
            {
                // Release file handles, otherwise they become locked by Lucee and cannot be interacted with
                if (isDefined("InputStream")) InputStream.close();
                if (isDefined("OutputStream")) OutputStream.close();
            }
        </cfscript>
    </cffunction>
</cfcomponent>