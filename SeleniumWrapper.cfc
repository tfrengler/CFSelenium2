<cfcomponent modifier="final" output="false">

	<!--- PRIVATE --->
	<cfset variables.ValidBrowsers = ["CHROME","EDGE","FIREFOX","IE"] />

	<!--- PUBLIC --->
	<cfset this.Browser = "" />
	<cfset this.Webdriver = null />
	<cfset this.Tools = null />
	<cfset this.GetElement = null />
	<cfset this.GetElements = null />

	<cffunction name="init" access="public" >
		<cfargument name="objectFactory" type="ObjectFactory" required="true" />
		<cfargument name="remoteURL" type="string" required="true" />
		<cfargument name="browser" type="string" required="false" />
		<cfargument name="browserArguments" type="array" required="false" />
		<cfargument name="driverOptions" type="any" required="false" />
		<cfscript>

		if (structKeyExists(arguments, "driverOptions"))
		{
			this.Webdriver = ObjectFactory.Get("OpenQA.Selenium.Remote.RemoteWebDriver").init(arguments.remoteURL, arguments.driverOptions);
			return this;
		}

		CreateDriverOptions(browser.Value, browserArguments);

		arrayFind(variables.ValidBrowsers, arguments.browser) == 0
			throw new Exception("");

		var Options = structKeyExists(arguments, "driverOptions") ? arguments.driverOptions : CreateDriverOptions(arguments.browser);

		var Options = options ?? CreateDriverOptions(browser.Value, browserArguments);
		Webdriver = new RemoteWebDriver(remoteURL, Options);

		GetElement = new ElementLocator(Webdriver);
		GetElements = new ElementsLocator(Webdriver);
		Tools = new SeleniumTools(Webdriver);

		if (!remoteURL.IsLoopback)
			Webdriver.FileDetector = new LocalFileDetector();

		return this;

		</cfscript>
	</cffunction>

	<cffunction name="CreateDriverOptions" access="private" returntype="any" >
		<cfargument name="objectFactory" type="ObjectFactory" required="true" />
		<cfargument name="browser" type="string" required="true" />
		<cfargument name="browserArguments" type="array" required="false" />

	</cffunction>
</cfcomponent>