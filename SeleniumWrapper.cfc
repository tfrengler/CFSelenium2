<cfcomponent modifier="final" output="false" hint="A lightweight wrapper around Selenium's RemoteWebDriver-class">

	<!--- PRIVATE --->
	<cfset variables.ValidBrowsers = ["CHROME","EDGE","FIREFOX","IE11"] />

	<!--- PUBLIC --->
	<cfset this.Webdriver = null />
    <cfset this.ObjectFactory = null />

	<cffunction name="init" output="true" access="public" returntype="SeleniumWrapper" hint="Constructor. Note that whule a lot of arguments are optional, some become required when others are not passed. Basically 'browser' and 'driverOptions' are mutually exclusive, with the latter taking precedence if both are passed" >
		<cfargument name="objectFactory" type="JavaObjectFactory" required="true" hint="An instance of 'JavaObjectFactory', used internally to create the necessary Java-objects" />
		<cfargument name="remoteURL" type="any" required="true" hint="The URL that the browser driver is running on, in the form of an instance of 'java.net.URL'. You get this from WebdriverManager.Start()" />
		<cfargument name="browser" type="string" required="false" default="DEFAULT_INVALID" hint="The browser you want this instance to represent. Mutually exclusive with 'driverOptions'. Will create the corresponding driver options for you, using certain default values (no proxy for all browser, a temp profile for Firefox, normal pageload strategy for Edge, using CreateProcess API to launch IE11)" />
		<cfargument name="browserArguments" type="array" required="false" default=#[]# hint="An array of string arguments to pass to the browser upon startup, such as '--headless' for Chrome for example" />
		<cfargument name="driverOptions" type="any" required="false" hint="An instance of the browser's Selenium DriverOption-class. Mutually exclusive with 'browser' and 'browserArguments'. Use this option to completely customize the browser options yourself, such as proxy, arguments etc" />
        <cfscript>
        
        if (!isInstanceOf(arguments.remoteURL, "java.net.URL"))
            throw(message="Error instantiating SeleniumWrapper", detail="Argument 'remoteURL' should be an instance of 'java.net.URL' but it isn't");

        this.ObjectFactory = arguments.objectFactory;
        var Options = null;

		if (structKeyExists(arguments, "driverOptions"))
            Options = arguments.driverOptions;
        else
        {
            if (arrayFind(variables.ValidBrowsers, arguments.browser) == 0)
                throw(message="Error instantiating SeleniumWrapper", detail="Since you didn't pass argument 'driverOptions', argument 'browser' is required. You passed this as '#arguments.browser#' which is not a valid value (#arrayToList(variables.ValidBrowsers)#)");
    
            Options = CreateDriverOptions(arguments.browser, arguments.browserArguments);
        }

        var RemoteURL = arguments.remoteURL;
        dump(RemoteURL.toString());

        var CreateWebdriverTask = runAsync(() => {
                return this.ObjectFactory.Get("org.openqa.selenium.remote.RemoteWebDriver").init(RemoteURL, Options);

        }, 5000).then((any remoteWebDriver)=> {
            this.Webdriver = arguments.remoteWebDriver;

        }).error((any error)=> throw(arguments.error));
        
        // throw(message="Error instantiating SeleniumWrapper", detail="Timed out creating session. RemoteURL is not reachable or something else is wrong (#RemoteURL#)"));
        
        if (!createObject("java", "java.net.InetAddress").getByName(arguments.remoteURL.getHost()).isLoopbackAddress())
            this.Webdriver.setFileDetector(this.ObjectFactory.Get("org.openqa.selenium.remote.LocalFileDetector").init());

		return this;

		</cfscript>
	</cffunction>

	<cffunction name="CreateDriverOptions" access="private" returntype="any" >
		<cfargument name="browser" type="string" required="true" />
        <cfargument name="browserArguments" type="array" required="false" />
        
        <cfscript>

        var ProxyType = this.ObjectFactory.Get("org.openqa.selenium.Proxy$ProxyType");
        var PageLoadStrategy = this.ObjectFactory.Get("org.openqa.selenium.PageLoadStrategy");

        switch(arguments.browser)
        {
            case "CHROME":
                var ChromeOptions = this.ObjectFactory.Get("org.openqa.selenium.chrome.ChromeOptions").init();
                if (arguments.browserArguments.len() > 0)
                    ChromeOptions.addArguments(arguments.browserArguments);
                else
                {
                    var Proxy = this.ObjectFactory.Get("org.openqa.selenium.Proxy").init();
                    Proxy.setAutodetect(false);
                    Proxy.setProxyType(ProxyType.DIRECT);
                    ChromeOptions.setProxy(Proxy);
                }

                return ChromeOptions;

            case "FIREFOX":
                var FirefoxOptions = this.ObjectFactory.Get("org.openqa.selenium.firefox.FirefoxOptions").init();

                if (arguments.browserArguments.len() > 0)
                    FirefoxOptions.addArguments(arguments.browserArguments);
                else
                {
                    FirefoxOptions.setProfile(this.ObjectFactory.Get("org.openqa.selenium.firefox.FirefoxProfile").init());
                    FirefoxOptions.addPreference("network.proxy.type", 0);
                }

                return FirefoxOptions;

            case "EDGE":
                // Edge has no options for adding arguments atm
                var EdgeOptions = this.ObjectFactory.Get("org.openqa.selenium.edge.EdgeOptions").init();
                EdgeOptions.setPageLoadStrategy(PageLoadStrategy.NORMAL);

                return EdgeOptions;

            case "IE11":
                var IEOptions = this.ObjectFactory.Get("org.openqa.selenium.ie.InternetExplorerOptions").init();
                if (arguments.browserArguments.len() > 0)
                {
                    IEOptions.useCreateProcessApiToLaunchIe();
                    IEOptions.addArguments(arguments.browserArguments);
                }
                else
                {
                    var Proxy = this.ObjectFactory.Get("org.openqa.selenium.Proxy").init();
                    Proxy.setAutodetect(false);
                    Proxy.setProxyType(ProxyType.DIRECT);
                    IEOptions.setProxy(Proxy);
                }

                return IEOptions;

            default:
                Dispose();
                throw("Internal error 101");
        };
        </cfscript>
    </cffunction>
    
    <cffunction name="Dispose" access="public" returntype="void" hint="Disposes of this instance of SeleniumWrapper, shutting down Selenium if it's running" >
        <cfscript>
            if(!isNull(variables.Webdriver))
                variables.Webdriver.Quit();
        </cfscript>
    </cffunction>
</cfcomponent>