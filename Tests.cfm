<!--- Disable proxy buffering, which allows us to use cfflush --->
<cfheader name="X-Accel-Buffering" value="no" />

<cfset SeleniumJars = directoryList(path="C:\Temp\selenium-java-3.141.59\", filter="*.jar", type="file") />

<!--- <cfset Javaloader = new JavaLoaderLib.javaloader.JavaLoader(SeleniumJars) /> --->
<!--- <cfset ObjectFactory = new JavaObjectFactory(javaloaderInstance=JavaLoader) /> --->

<cfset ObjectFactory = new JavaObjectFactory(jarFolder="C:\Temp\selenium-java-3.141.59\") />
<cfset By = ObjectFactory.Get("org.openqa.selenium.By") />

<cfset ChromeTest = true />
<cfset FirefoxTest = true />

<cftry>
    <cfset Webdrivers = new WebdriverManager(ObjectFactory, "C:\Temp\Webdrivers\") />

    <cfdump var=#Webdrivers.GetLatestWebdriverBinary("CHROME", "WINDOWS", "x86")# />
    <cfdump var=#Webdrivers.GetLatestWebdriverBinary("FIREFOX", "WINDOWS", "x64")# />

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
    <cfif isDefined("Webdriver")>
        <cfset Webdrivers.Dispose() />
    </cfif>

    <cfrethrow/>
</cfcatch>
</cftry>

<hr/>
<cfdump var="Disposing the WebdriverManager-instance" />
<cfset Webdrivers.Dispose() />
<cfdump var="All done! Check running processes to see if there are any lingering 'chromedriver' or 'geckodriver' instances around (there shouldn't be...)" />