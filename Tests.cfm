<!--- Disable proxy buffering, which allows us to use cfflush --->
<cfheader name="X-Accel-Buffering" value="no" />
<cfset ObjectFactory = new JavaObjectFactory(jarFolder="C:\Temp\selenium-java-3.141.59\") />
<cfset By = ObjectFactory.Get("org.openqa.selenium.By") />

<cfset ChromeTest = false />
<cfset FirefoxTest = true />

<cftry>

    <!--- <cfscript>
        OutputFile = createObject("java", "java.io.File").init("C:\Temp\log.txt");
        // OutputStream = createObject("java", "java.io.FileWriter").init(OutputFile);
        Executable = createObject("java", "java.io.File").init("C:\Temp\Webdrivers\chromedriver.exe");
        ServiceBuilder = ObjectFactory.Get("org.openqa.selenium.chrome.ChromeDriverService$Builder").init();
        ServiceBuilder.usingDriverExecutable(Executable);
        ServiceBuilder.usingAnyFreePort();
        ServiceBuilder.withLogFile(OutputFile);
        Service = ServiceBuilder.Build();
        Service.Start();
        dump("service started");
        cfflush();

        Selenium = new SeleniumWrapper(ObjectFactory, Service.getUrl(), "CHROME");
        dump("browser started");
        cfflush();
    </cfscript> --->

    <cfset Webdrivers = new WebdriverManager(ObjectFactory, "C:\Temp\Webdrivers\") />

    <!--- CHROME --->
    <cfif ChromeTest >
        <cfdump var="Starting CHROME tests" />
        <cfset RemoteURL = Webdrivers.Start("CHROME") />
        <cfdump var=#RemoteURL.toString()# label="Webdriver URL" />
        <cfdump var="Driver started" />
        <cfflush/>

        <cfset Selenium = new SeleniumWrapper(ObjectFactory, RemoteURL, "CHROME") />

        <cfdump var="SeleniumWrapper created" />
        <cfflush/>

        <cfdump var="Starting browser interaction" />
        <cfflush/>
        <cfset Selenium.Webdriver.navigate().to("https://www.selenium.dev/documentation/en/getting_started/") />
        <cfset Element = Selenium.Webdriver.FindElement(By.CssSelector("nav##sidebar")) />

        <cfset ClassAttribute = Element.getAttribute("class") />
        <cfif ClassAttribute NEQ "showVisitedLinks" >
            <cfdump var="Error, expected 'Element.getAttribute(""class"")' to be 'showVisitedLinks', but instead it's: #ClassAttribute#" />
        </cfif>

        <cfset IsChromeRunning = Webdrivers.IsRunning("CHROME") />
        <cfset IsFirefoxRunning = Webdrivers.IsRunning("FIREFOX") />

        <cfset IsChromeStopped = Webdrivers.Stop("CHROME") />
        <cfset IsFirefoxStopped = Webdrivers.Stop("FIREFOX") />

        <cfif IsChromeRunning IS false >
            <cfdump var="Error, Webdrivers reports CHROME is not running but it should be" />
        </cfif>
        <cfif IsFirefoxRunning IS true >
            <cfdump var="Error, Webdrivers reports FIREFOX is running but it should not" />
        </cfif>

        <cfif IsChromeStopped IS false >
            <cfdump var="Error, Webdrivers reports CHROME is was not stopped but it have been" />
        </cfif>
        <cfif IsFirefoxStopped IS true >
            <cfdump var="Error, Webdrivers reports FIREFOX is was stopped but it should not have been" />
        </cfif>

        <cfset Selenium.Dispose() />
        <cfdump var="CHROME tests done" />
        <hr/>
    </cfif>

    <!--- FIREFOX --->
    <cfif FirefoxTest >
        <cfdump var="Starting FIREFOX tests" />
        <cfset RemoteURL = Webdrivers.Start("FIREFOX") />
        <cfdump var=#RemoteURL.toString()# label="Webdriver URL" />
        <cfdump var="Driver started" />
        <cfflush/>

        <cfset Selenium = new SeleniumWrapper(ObjectFactory, RemoteURL, "FIREFOX") />

        <cfdump var="SeleniumWrapper created" />
        <cfflush/>

        <cfdump var="Starting browser interaction" />
        <cfflush/>
        <cfset Selenium.Webdriver.navigate().to("https://www.selenium.dev/documentation/en/getting_started/") />
        <cfset Element = Selenium.Webdriver.FindElement(By.CssSelector("nav##sidebar")) />

        <cfset ClassAttribute = Element.getAttribute("class") />
        <cfif ClassAttribute NEQ "showVisitedLinks" >
            <cfdump var="Error, expected 'Element.getAttribute(""class"")' to be 'showVisitedLinks', but instead it's: #ClassAttribute#" />
        </cfif>

        <cfset IsChromeRunning = Webdrivers.IsRunning("CHROME") />
        <cfset IsFirefoxRunning = Webdrivers.IsRunning("FIREFOX") />

        <cfset Selenium.Dispose() />
        <cfset IsChromeStopped = Webdrivers.Stop("CHROME") />
        <cfset IsFirefoxStopped = Webdrivers.Stop("FIREFOX") />

        <cfif IsChromeRunning IS true >
            <cfdump var="Error, Webdrivers reports CHROME is running but it shouldn't be" />
        </cfif>
        <cfif IsFirefoxRunning IS false >
            <cfdump var="Error, Webdrivers reports FIREFOX isn't running but it should be" />
        </cfif>

        <cfif IsChromeStopped IS true >
            <cfdump var="Error, Webdrivers reports CHROME is was stopped but it should not have been" />
        </cfif>
        <cfif IsFirefoxStopped IS false >
            <cfdump var="Error, Webdrivers reports FIREFOX is was not stopped but it should have been" />
        </cfif>

        <cfdump var="FIREFOX tests done" />
    </cfif>
<cfcatch>
    <!--- <cfset Service.Stop() /> --->
    <cfset Webdrivers.Dispose() />
    <cfrethrow/>
</cfcatch>
</cftry>

<!--- <cfset Service.Stop() /> --->
<cfset Webdrivers.Dispose() />