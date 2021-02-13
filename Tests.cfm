<!--- Disable proxy buffering, which allows us to use cfflush --->
<cfheader name="X-Accel-Buffering" value="no" />
<cfset ObjectFactory = new JavaObjectFactory(jarFolder="C:\Temp\selenium-java-3.141.59\") />
<cfset By = ObjectFactory.Get("org.openqa.selenium.By") />

<cftry>

    <cfscript>
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
    </cfscript>

    <!--- <cfset TestURL = createObject("java", "java.net.URL").init("http://localhost:#Service.getUrl().getPort().toString()#/status") />

    <cfdump var=#TestURL.toString()# />
    <cfset WebdriverConnection = TestURL.openConnection() />
    <cfset WebdriverConnection.setRequestMethod("HEAD") />
    <cfdump var=#WebdriverConnection.getResponseCode()# />
    
    <cfset Webdrivers = new WebdriverManager(ObjectFactory, "C:\Temp\Webdrivers\") />
    <cfset By = ObjectFactory.Get("org.openqa.selenium.By") /> --->

    <!--- CHROME ---> 
    <!--- <cfset RemoteURL = Webdrivers.Start("CHROME") />
    <cfdump var=#RemoteURL# label="RemoteURL" />
    <cfdump var="Driver started" />
    <cfflush/>

    <cfset Selenium = new SeleniumWrapper(ObjectFactory, RemoteURL, "CHROME") />
    
    <cfdump var="SeleniumWrapper created" />
    <cfflush/>
    --->
    <cfdump var="starting interaction" />
    <cfflush/>
    <cfset Selenium.Webdriver.navigate().to("https://www.selenium.dev/documentation/en/getting_started/") />
    <cfset Element = Selenium.Webdriver.FindElement(By.CssSelector("nav##sidebar")) />
    
    <cfdump var=#Element.getAttribute("class")# />

    <!--- <cfdump var=#Webdrivers.IsRunning("FIREFOX")# label="IS RUNNING: FIREFOX" />
    <cfdump var=#Webdrivers.IsRunning("CHROME")# label="IS RUNNING: CHROME" />
    
    <cfdump var=#Webdrivers.Stop("CHROME")# label="STOPPED: CHROME" />
    <cfdump var=#Webdrivers.Stop("FIREFOX")# label="STOPPED: FIREFOX" /> --->

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
    <cfset Service.Stop() />
    <!--- <cfset Webdrivers.Dispose() /> --->
    <cfrethrow/>
</cfcatch>
</cftry>

<cfset Service.Stop() />
<!--- <cfset Webdrivers.Dispose() /> --->