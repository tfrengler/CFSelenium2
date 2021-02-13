<cfcomponent output="false" modifier="final" hint="Utility component for creating Java objects based on how the jar-files are made available to your application. By default, if you instantiate it with no parameters, it will simply use createObject() with no additional arguments" >
	<!---
		Creation strategies:
		0 - Default, use createObject with no additional parameters. User is responsible for making the Java jars available to CF/Lucee somehow
		1 - Use Mark Mandel's excellent javaloader
		2 - Use the bundle name-parameter of createObject to pass the full path to the folder where the Java jars are available
	--->

	<cfset variables.CreationStrategy = -1 />
	<cfset variables.JavaLoader = null />
	<cfset variables.JarFolder = "" />

	<cffunction name="init" returntype="JavaObjectFactory" access="public" hint="Constructor" >
		<cfargument name="javaloaderInstance" type="any" required="false" hint="Instance of Mark Mandel's JavaLoader. If you for some reason pass both arguments, then the Javaloader takes precedence." />
		<cfargument name="jarFolder" type="string" required="false" hint="Full path to folder where all the Java jars are located. Does not work in ACF." />
		<cfscript>

		if (structKeyExists(arguments, "javaloaderInstance") AND isObject(arguments.javaloaderInstance))
		{
			variables.JavaLoader = arguments.javaloaderInstance;
			variables.CreationStrategy = 1;

			return this;
		}

		if (structKeyExists(arguments, "jarFolder") AND directoryExists(arguments.jarFolder))
		{
			variables.JarFolder = arguments.jarFolder;
            var JarCheck = directoryList(variables.JarFolder, false, "name", "*.jar", "asc", "file");
            
            if (JarCheck.len() == 0)
                throw("Unable to instantiate JavaObjectFactory. You passed a directory which exists, but does not appear to have any jar-files in it (#arguments.jarFolder#)");

			variables.CreationStrategy = 2;
            return this;
		}

		variables.CreationStrategy = 0;
		return this;

		</cfscript>
	</cffunction>

	<cffunction name="Strategy" returntype="string" access="public" hint="Returns the strategy used for creating Java objects" >
		<cfscript>
            switch(variables.CreationStrategy)
            {
                case 0:
                    return "STANDARD";
                case 1:
                    return "JAVALOADER";
                case 2:
                    return "JAR_PATH";

                default:
                    return "ERROR";
            }
        </cfscript>
	</cffunction>

	<cffunction name="Get" returntype="any" access="public" hint="Creates and returns a given Java object. The returned object is a static handle, so you still have to call init() on it yourself." >
		<cfargument name="class" type="string" required="true" hint="Name of the Java Java-class you wish to create a handle for" />

		<cfscript>
            switch(variables.CreationStrategy)
            {
                case 0:
                    return createObject("java", arguments.class);
                case 1:
                    return variables.JavaLoader.create(arguments.class);
                case 2:
                    return createObject("java", arguments.class, variables.JarFolder);

                default:
                    throw(message="Error getting Java object", detail="The creation strategy is incorrect: #variables.CreationStrategy#");
            }
        </cfscript>
	</cffunction>

</cfcomponent>