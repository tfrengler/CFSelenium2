<cfcomponent modifier="final" output="false" hint="Manages the lifecycle of browser webdrivers">

    <!--- PRIVATE --->
    <cfset variables.OS = createObject("java", "java.lang.System").getProperty("os.name").toLowerCase() />
    <cfset variables.IS_WINDOWS = (find("win", variables.OS) GT 0) />
    <cfset variables.IS_MAC = (find("mac", variables.OS) GT 0) />
    <cfset variables.IS_UNIX = (find("nix", variables.OS) GT 0 OR find("nux", variables.OS) GT 0 OR find("aix", variables.OS) GT 0) />
    <cfset variables.IsDisposed = false />

    <cfset variables.ValidBrowsers = ["CHROME","EDGE","FIREFOX","IE11"] />
    <cfset variables.DriverNames = {
        EDGE: "msedgedriver",
        FIREFOX: "geckodriver",
        CHROME: "chromedriver",
        IE11: "IEDriverServer"
    } />

    <cfset variables.DriverServices = {
        CHROME: null,
        EDGE: null,
        FIREFOX: null,
        IE11: null
    } />

    <cfset variables.DriverFolder = null />
    <cfset variables.ObjectFactory = null />
    <cfset variables.IsValidBrowser = function(required string name) { return arrayFind(variables.ValidBrowsers, arguments.name) == 0 } />

    <cffunction name="init" access="public" returntype="WebdriverManager" hint="Constructor" >
		<cfargument name="objectFactory" type="JavaObjectFactory" required="true" hint="An instance of 'JavaObjectFactory', used internally to create the necessary Java-objects" />
        <cfargument name="driverFolder" type="string" required="true" hint="Path to the folder wherein the webdriver executables are found" />
        <cfscript>

        if (!directoryExists(arguments.DriverFolder))
            throw(message="Error instantiating WebdriverManager", detail="The folder given in argument 'DriverFolder' does not exist: #arguments.DriverFolder#");

        variables.DriverFolder = arguments.DriverFolder;
        variables.ObjectFactory = arguments.objectFactory;

        </cfscript>
    </cffunction>

    <cffunction name="Start" access="public" returntype="any" hint="Starts the webdriver for a given browser, and returns the URL it's running on in the form of an instance of 'java.net.URL'" >
        <cfargument name="browser" type="string" required="true" hint="The name of the browser whose webdriver you wish to start" />
        <cfargument name="killExisting" type="boolean" required="false" default="false" hint="If passed as true it will shut down any already running webdrivers. If passed as false (which is the default) and the webdriver is already running, an exception will be thrown" />
        <cfargument name="port" type="numeric" required="false" default="0" hint="The port to start the webdriver on. By default, the webdriver will start on a random, free port on the system" />
        <cfscript>

        if (variables.IsValidBrowser(arguments.browser))
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

        if (!arguments.killExisting && !isNull(Service))
        {
            Dispose();
            throw(message="Unable start #arguments.browser#-driver", detail="It appears to already be running (and argument 'killExisting' is false)");
        }

        if (arguments.killExisting && !isNull(Service))
            Stop(browser);

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

    <cffunction name="Stop" access="public" returntype="boolean" hint="Stops a given webdriver, shutting all browser instances associated with it as well" >
        <cfargument name="browser" type="string" required="true" hint="The name of the browser whose webdriver you wish to shut down" />
        <cfscript>

        if (variables.IsValidBrowser(arguments.browser))
        {
            Dispose();
            throw(message="Unable to stop browser driver", detail="Argument 'browser' (#arguments.browser#) is not a valid value (#arrayToList(variables.ValidBrowsers)#)");
        }

        var Service = DriverServices[arguments.browser];
        if (isNull(Service))
            return false;

        Service.stop();
        DriverServices[arguments.browser] = null;

        return true;
        </cfscript>
    </cffunction>

    <cffunction name="IsRunning" access="public" returntype="boolean" hint="Check whether the given webdriver is running or not" >
        <cfargument name="browser" type="string" required="true" hint="The name of the browser whose status you want to check" />
        <cfscript>

        if (variables.IsValidBrowser(arguments.browser))
        {
            Dispose();
            throw(message="Unable to check browser status", detail="Argument 'browser' (#arguments.browser#) is not a valid value (#arrayToList(variables.ValidBrowsers)#)");
        }

        var Service = DriverServices[arguments.browser];
        if (isNull(Service))
            return false;

        return Service.isRunning();
        </cfscript>
    </cffunction>

    <cffunction name="Dispose" access="public" returntype="void" hint="Disposes of this WebdriverManager-instance, releasing all held resources by shutting down all open webdrivers" >
        <cfscript>
            if (variables.IsDisposed) return;
            variables.IsDisposed = true;

            for(var BrowserName in variables.DriverServices)
                Stop(BrowserName);
        </cfscript>
    </cffunction>
</cfcomponent>