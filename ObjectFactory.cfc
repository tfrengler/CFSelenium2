<cfcomponent output="false" modifier="final" hint="Utility component for creating Selenium objects based on how the jar-files are made available to your application. By default, if you instantiate it with no parameters, it will simply use createObject() with no additional arguments" >
	<!---
		Creation strategies:
		0 - Default, use createObject with no additional parameters. User is responsible for making the Selenium jars available to CF/Lucee somehow
		1 - Use Mark Mandel's excellent javaloader
		2 - Use the bundle name-parameter of createObject to pass the full path to the folder where the Selenium jars are available
	--->

	<cfset variables.CreationStrategy = -1 />
	<cfset variables.JavaLoader = null />
	<cfset variables.SeleniumJarsPath = "" />

	<cffunction name="init" returntype="ObjectFactory" access="public" hint="Constructor" >
		<cfargument name="javaloaderInstance" type="any" required="false" hint="Instance of Mark Mandel's JavaLoader. If you for some reason pass both arguments, then the Javaloader takes precedence." />
		<cfargument name="jarFolder" type="string" required="false" hint="Full path to folder where all the Selenium jars are located. Does not work in ACF." />
		<cfscript>

		if (structKeyExists(arguments, "javaloaderInstance") AND isObject(arguments.javaloaderInstance))
		{
			variables.JavaLoader = arguments.javaloaderInstance;
			variables.CreationStrategy = 1;

			return this;
		}

		if (structKeyExists(arguments, "jarFolder") AND directoryExists(arguments.jarFolder))
		{
			variables.SeleniumJarsPath = arguments.jarFolder;
			variables.CreationStrategy = 2;
		}

		variables.CreationStrategy = 0;
		return this;

		</cfscript>
	</cffunction>

	<cffunction name="Strategy" returntype="string" access="public" hint="Returns the strategy used for creating Selenium objects" >
		<cfswitch expression=#variables.CreationStrategy# >
			<cfcase value="0">
				<cfreturn "STANDARD" />
			</cfcase>
			<cfcase value="1">
				<cfreturn "JAVALOADER" />
			</cfcase>
			<cfcase value="2">
				<cfreturn "JAR_PATH" />
			</cfcase>

			<cfdefaultcase>
				<cfreturn "ERROR" />
			</cfdefaultcase>
		</cfswitch>
	</cffunction>

	<cffunction name="Get" returntype="any" access="public" hint="Creates and returns a given Selenium object. The returned object is a static handle, so you still have to call init() on it yourself." >
		<cfargument name="class" type="string" required="true" hint="Name of the Selenium Java-class you wish to create an instance of." />

		<cfswitch expression=#variables.CreationStrategy# >
			<cfcase value="0">
				<cfreturn createObject("java", arguments.class) />
			</cfcase>
			<cfcase value="1">
				<cfreturn variables.JavaLoader.create(arguments.class) />
			</cfcase>
			<cfcase value="2">
				<cfreturn createObject("java", arguments.class, variables.SeleniumJarsPath) />
			</cfcase>

			<cfdefaultcase>
				<cfthrow message="Error getting Selenium object" detail="The creation strategy is incorrect: #variables.CreationStrategy#" />
			</cfdefaultcase>
		</cfswitch>
	</cffunction>

</cfcomponent>