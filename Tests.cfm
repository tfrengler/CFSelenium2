<!--- Disable proxy buffering, which allows us to use cfflush --->
<cfheader name="X-Accel-Buffering" value="no" />

<cfset ObjectFactory = new JavaObjectFactory(jarFolder="C:\Temp\selenium-java-3.141.59\") />
<cfset Webdrivers = new WebdriverManager(ObjectFactory, "C:\Temp\Webdrivers\") />

<cftry>

    <cfset By = ObjectFactory.Get("org.openqa.selenium.By") />

    <!--- CHROME --->
    <cfset RemoteURL = Webdrivers.Start("CHROME") />
    <cfdump var="Driver started" />
    <cfflush/>

    <cfset Selenium = new SeleniumWrapper(ObjectFactory, RemoteURL, "CHROME") />
    
    <cfdump var="SeleniumWrapper created" />
    <cfflush/>

    <cfset Selenium.Webdriver.navigate().to("https://www.selenium.dev/documentation/en/getting_started/") />
    <cfset Element = Selenium.Webdriver.FindElement(By.CssSelector("nav##sidebar")) />
    
    <cfdump var=#Element.getAttribute("class")# />

    <cfdump var=#Webdrivers.IsRunning("FIREFOX")# label="IS RUNNING: FIREFOX" />
    <cfdump var=#Webdrivers.IsRunning("CHROME")# label="IS RUNNING: CHROME" />
    
    <cfdump var=#Webdrivers.Stop("CHROME")# label="STOPPED: CHROME" />
    <cfdump var=#Webdrivers.Stop("FIREFOX")# label="STOPPED: FIREFOX" />

    <!--- FIREFOX --->
    <!--- <cfset RemoteURL = Webdrivers.Start("FIREFOX") />
    <cfset Selenium = new SeleniumWrapper(ObjectFactory, RemoteURL, "FIREFOX") />

    <cfset Selenium.Webdriver.navigate().to("https://www.selenium.dev/documentation/en/getting_started/") />
    <cfset Element = Selenium.Webdriver.FindElement(By.CssSelector("nav##sidebar")) />
    
    <cfdump var=#Element.getAttribute("class")# />

    <cfdump var=#Webdrivers.IsRunning("FIREFOX")# label="IS RUNNING: FIREFOX" />
    <cfdump var=#Webdrivers.IsRunning("CHROME")# label="IS RUNNING: CHROME" />
    
    <cfdump var=#Webdrivers.Stop("CHROME")# label="STOPPED: CHROME" />
    <cfdump var=#Webdrivers.Stop("FIREFOX")# label="STOPPED: FIREFOX" /> --->

<cfcatch>
    <cfset Webdrivers.Dispose() />
    <cfrethrow/>
</cfcatch>
</cftry>

<cfset Webdrivers.Dispose() />