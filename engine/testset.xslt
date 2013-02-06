<?xml version="1.0" encoding="utf-8"?>
<!--    testset.xslt
//      
//      Copyright (C) 2011, Institute for System Programming
//                          of the Russian Academy of Sciences (ISPRAS)
//      Authors:
//      	Ruzanna Karakozova <r.karakozova@gmail.com>
//			Vahram Martirosyan <vmartirosyan@gmail.com>
//      
//      This program is free software; you can redistribute it and/or modify
//      it under the terms of the GNU General Public License as published by
//      the Free Software Foundation; either version 2 of the License, or
//      (at your option) any later version.
//      
//      This program is distributed in the hope that it will be useful,
//      but WITHOUT ANY WARRANTY; without even the implied warranty of
//      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//      GNU General Public License for more details.
//      
//      You should have received a copy of the GNU General Public License
//      along with this program; if not, write to the Free Software
//      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
//      MA 02110-1301, USA.
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="text" encoding="utf-8" />
	

<xsl:template match="/TestSet">
		<xsl:param name="ModuleName" />
		<xsl:param name="TestClassName" />
	<xsl:value-of select="GlobalHeader"/>
	<xsl:for-each select="Requires">
#include &lt;<xsl:value-of select="." />>
	</xsl:for-each> 

#include &lt;map>
#include &lt;Process.hpp>
#include &lt;memory>
#include &lt;UnixCommand.hpp>
#include &lt;KedrIntegrator.hpp>
#include &lt;PartitionManager.hpp>
#include &lt;Logger.hpp>
using std::map;
using std::string;
	<xsl:variable name="TestSetName" select="@Name" />
	
class <xsl:value-of select="$TestClassName" /> : public Process
{
	struct Test
	{
		Test(string desc = "", int (<xsl:value-of select="$TestClassName" />::*func)(vector&lt;string>) = NULL):
			_description(desc),
			_func(func)
			{}
		string _description;
		int (<xsl:value-of select="$TestClassName" />::*_func)(vector&lt;string>);
	};
	
	typedef map&lt;string, Test> TestMap;
public:
	<xsl:value-of select="$TestClassName" />():
		Process(TEST_TIMEOUT),
		_tests_to_run(),
		_tests_to_exclude(),
		_name("<xsl:value-of select="$TestClassName" />"),
		_fsim_enabled(false),
		_fsim_point("kmalloc"),		
		_fsim_expression("0"),		
		_tests(),
		_fsim_tests(),
		_fault_count(0),
		_fsim_info_vec(),
		_DirPrefix("<xsl:value-of select="$TestClassName" />_<xsl:value-of select="@Name"/>_dir_"),
		_FilePrefix("<xsl:value-of select="$TestClassName" />_<xsl:value-of select="@Name"/>_file_")
		//_testCount(<xsl:value-of select="count(Test)"/>),
		//_fsim_testCount(<xsl:value-of select="count(Test[@FaultSimulationReady='true'])"/>)		
	{			
	
	<xsl:for-each select="Test">
		_tests["<xsl:value-of select="@Name"/>"] = Test( "<xsl:value-of select="Description"/>", &amp;<xsl:value-of select="$TestClassName" />::<xsl:value-of select="@Name" />Func);
	</xsl:for-each>
	<xsl:for-each select="Test[@FaultSimulationReady='true']">
		_fsim_tests["<xsl:value-of select="@Name"/>"] = Test("<xsl:value-of select="Description"/>", &amp;<xsl:value-of select="$TestClassName" />::<xsl:value-of select="@Name" />Func);
	</xsl:for-each>
	
		struct FSimInfo info;
	<xsl:for-each select="FaultSimulation/Simulate">
	<xsl:if test="@point">
		info.Point = "<xsl:value-of select="@point" />";
	</xsl:if>
	<xsl:if test="@count">
		info.Count = <xsl:value-of select="@count" />;
	</xsl:if>
	<xsl:if test="@expression">
		info.Expression = "<xsl:value-of select="@expression" />";
	</xsl:if>
		_fsim_info_vec.push_back(info);
	</xsl:for-each>
		if( _fsim_info_vec.empty() &amp;&amp;  !_fsim_tests.empty() )
		{
			info.Point = "kmalloc";
			_fsim_info_vec.push_back(info);
		}
	}
	~<xsl:value-of select="$TestClassName" />()
	{

	}
	string GetName() { return _name; }
	void ExcludeTest(string test)
	{
		if ( _tests[test]._func != NULL )
		{
			cerr &lt;&lt; "\n\t Test should be excluded: " &lt;&lt; test &lt;&lt; endl;
			_tests_to_exclude.push_back(test);
		}
		else
			throw Exception("Unknown test " + test);
	}
	void RunTest(string test)
	{
		if ( _tests[test]._func != NULL )
			_tests_to_run.push_back(test);
		else
			throw Exception("Unknown test " + test);
	}
	
	bool IsTestExcluded(string test)
	{
		return (std::find(_tests_to_exclude.begin(), _tests_to_exclude.end(), test) != _tests_to_exclude.end());
	}
	
	virtual TestResultCollection RunNormalTests()
	{
		<xsl:value-of select="StartUp"/>
		chdir(MountPoint);
		TestResultCollection res;
		//for ( unsigned int i  = 0; i &lt; _tests.size(); ++i)
		if ( _tests_to_run.empty() )
		{
			for ( TestMap::iterator it = _tests.begin(); it != _tests.end(); ++it )
			{
				<xsl:value-of select="$ModuleName"/>TestResult * tr = NULL;
				// Check if the test is set to be excluded
				std::auto_ptr&lt;ProcessResult> pr;
				if ( IsTestExcluded(it->first) )
				{
					tr = new <xsl:value-of select="$ModuleName"/>TestResult(new ProcessResult(Skipped, "Test was excluded"), "<xsl:value-of select="$TestSetName" />", it->first, it->second._description);
				}
				else
				{
					Logger::LogInfo("Running test: " + it->first);
					pr = std::auto_ptr&lt;ProcessResult>( Execute(static_cast&lt;int (Process::*)(vector&lt;string>)>(it->second._func)) );
					Logger::LogInfo("Test  " + it->first + " completed.");
					tr = new <xsl:value-of select="$ModuleName"/>TestResult(pr.get(), "<xsl:value-of select="$TestSetName" />", it->first, it->second._description);
				
				}

				string log;
				Status oopsStatus = OopsChecker(log); // log is an output parameter
				if(oopsStatus != Success) 
				{	
					//so we have an emergency situation...
					cerr&lt;&lt;"Oops Checker is activated: \n";
					log = "Status: " + StatusMessages[oopsStatus] + "\nTest output: \n" + pr->GetOutput() + "\nSystem log message: \n" + log;
					tr = new <xsl:value-of select="$ModuleName"/>TestResult(new ProcessResult(Fatal, log),"<xsl:value-of select="$TestSetName" />", it->first, it->second._description);
				}
			
				res.AddResult( tr );
				// If Fatal error has rised quit!
				if ( tr->GetStatus() == Fatal )
					break;
			}
		}
		else
		{
			for ( unsigned int i = 0; i &lt; _tests_to_run.size(); ++i )
			{				
				ProcessResult * pr = Execute(static_cast&lt;int (Process::*)(vector&lt;string>)>(_tests[_tests_to_run[i]]._func));
				<xsl:value-of select="$ModuleName"/>TestResult * tr = new <xsl:value-of select="$ModuleName"/>TestResult(pr, "<xsl:value-of select="$TestSetName" />", _tests_to_run[i], _tests[_tests_to_run[i]]._description);
				delete pr;
				res.AddResult( tr );
			}
		}
		<xsl:value-of select="CleanUp"/>
		return res;
	}
	
	
	virtual TestResultCollection RunFaultyTests()
	{
		<xsl:value-of select="StartUp"/>
		cerr &lt;&lt; "Running faulty tests:  <xsl:value-of select="$TestSetName" />: " &lt;&lt; _fsim_info_vec.size() &lt;&lt; endl;
		_fsim_enabled = true;
		TestResultCollection res;
	
		for ( unsigned int i = 0; i &lt; _fsim_info_vec.size(); ++i )
		{
			_fsim_point = _fsim_info_vec[i].Point;
			_fsim_expression = "0";
			//KedrIntegrator::SetIndicator(_fsim_point, "common", _fsim_expression);	
			
			 TestMap::iterator it = _fsim_tests.begin();
			 cerr &lt;&lt; "\033[1;31mCalling: Test name: " &lt;&lt; it->first &lt;&lt; "\t. Parent pid: " &lt;&lt; getpid() &lt;&lt; ".\033[0m" &lt;&lt; endl;
				ProcessResult * pr = Execute((int (Process::*)(vector&lt;string>))it->second._func);
				//if ( pr->GetStatus() >= Success &amp;&amp;  pr->GetStatus() &lt;= Fail )
						//pr->SetStatus(Success);
					cerr &lt;&lt; "\033[1;31mCalled: Test name: " &lt;&lt; it->first &lt;&lt; "\t. Parent pid: " &lt;&lt; getpid() &lt;&lt; ".\033[0m" &lt;&lt; endl;
					<xsl:value-of select="$ModuleName"/>TestResult * tr = new <xsl:value-of select="$ModuleName"/>TestResult(pr, "<xsl:value-of select="$TestSetName" />", it->first, it->second._description);
					delete pr;
					res.AddResult( tr );
					
					if ( tr->GetStatus() == Signaled )
					{
						DisableFaultSim();
						return res;
					}
			
			_fsim_info_vec[i].Count = KedrIntegrator::GetTimes(_fsim_point);
			KedrIntegrator:: ResetTimes(_fsim_point);
			//DisableFaultSim();
			cerr &lt;&lt; "<xsl:value-of select="$TestSetName" />: Fault count: " &lt;&lt; _fsim_info_vec[i].Count &lt;&lt; endl;
		}
		
		
		for ( TestMap::iterator it = _fsim_tests.begin(); it != _fsim_tests.end(); ++it )
		for ( unsigned int i = 0; i &lt; _fsim_info_vec.size(); ++i )
		{
			cerr &lt;&lt; "<xsl:value-of select="$TestSetName" />: Fault count: " &lt;&lt; _fsim_info_vec[i].Count &lt;&lt; endl;
			_fsim_point = _fsim_info_vec[i].Point;			
			for ( unsigned int j = 1; j &lt; _fsim_info_vec[i].Count+1; ++j ) 
			{
				if ( _fsim_info_vec[i].Expression != "" )
					_fsim_expression = _fsim_info_vec[i].Expression;
				else
				{
					const int size = 10;
					char buf[size];
					if ( snprintf(buf, size, "%d", j) >= size)
					{
						Logger::LogError("Cannot get 'times' value.");
						break;
					}
					//_fsim_expression = "(times%" + (string)buf + " = 0)";
					_fsim_expression = "times="+(string)buf;
					
				}
				//for ( unsigned int k = 0; k &lt; _fsim_testCount; ++k)
				
					ProcessResult * pr = Execute((int (Process::*)(vector&lt;string>))it->second._func);
					//if ( pr->GetStatus() >= Success &amp;&amp;  pr->GetStatus() &lt;= Fail )
						//pr->SetStatus(Success);
					if( _fsim_info_vec[i].Count > 0 &amp;&amp;  pr->GetStatus() == Success )
					{
						pr->SetStatus(FSimSuccess);
						pr->ModOutput("Test returned Success instead of Fail. Fault Simulation failed.");	
					}
					if( _fsim_info_vec[i].Count > 0 &amp;&amp; pr->GetStatus() == Fail )
						pr->SetStatus(FSimFail);
					<xsl:value-of select="$ModuleName"/>TestResult * tr = new <xsl:value-of select="$ModuleName"/>TestResult(pr, "<xsl:value-of select="$TestSetName" />", it->first, it->second._description);
					delete pr;
					res.AddResult( tr );
					// If one of the tests makes the process to get a signal, then the driver probably is not functional any more.
					if ( tr->GetStatus() == Signaled )
					{
						DisableFaultSim();
						return res;
					}
				
				//DisableFaultSim();
			}
			//DisableFaultSim();	
		}
		
		DisableFaultSim();
		<xsl:value-of select="CleanUp"/>
		return res;
	}
	
	// The test functions
	<xsl:for-each select="Test">
	int <xsl:value-of select="@Name" />Func(vector&lt;string>)
	{
		
		Status _TestStatus = Success;
		<xsl:if test="@Shallow='true'" >
		_TestStatus = Shallow;
		</xsl:if>
		bool _InFooter = false;	
		if ( _InFooter == true )
			_InFooter = false;
			
<!-- Check if all the requirements are satisfied -->
		<xsl:if test="Requires">
			<xsl:if test="Requires/@KernelVersion!=''">
#if LINUX_VERSION_CODE &lt; KERNEL_VERSION(<xsl:value-of select="Requires/@KernelVersion" />)
		Unsupp("Kernel version should be at least <xsl:value-of select="Requires/@KernelVersion" />");
#endif
			</xsl:if>
			<xsl:if test="Requires/@Defined!=''">
#ifndef <xsl:value-of select="Requires/@Defined" />
		Unsupp("The value of <xsl:value-of select="Requires/@Defined" /> is not defined.");
#endif
			</xsl:if>			
		</xsl:if>
			
		<xsl:if test="@FaultSimulationReady='true'">
		if ( PartitionManager::IsOptionEnabled("ro") )
			Unsupp("Read-only file system.");
		</xsl:if>
		
		<xsl:value-of select="/TestSet/Header" />
			
		<xsl:value-of select="Header" />		
		//cerr &lt;&lt; "Description: " &lt;&lt; "<xsl:value-of select="Description" />" &lt;&lt; endl;
		try
		{
			string DirPrefix = _DirPrefix;
			DirPrefix.append(static_cast&lt;string>("<xsl:value-of select="@Name" />_"));
			string FilePrefix = _FilePrefix;
			FilePrefix.append(static_cast&lt;string>("<xsl:value-of select="@Name" />_"));
			<xsl:if test="Dir">
			const int DirCount = <xsl:value-of select="Dir/@count"/>;
			string DirPaths[DirCount];
			Directory Dirs[DirCount];
			int DirDs[DirCount];
			<xsl:if test="Dir/File">
			const int DirFileCount = <xsl:value-of select="Dir/File/@count"/>;
			string DirFilePaths[DirFileCount];
			File DirFiles[DirFileCount];
			int DirFDs[DirFileCount];
			</xsl:if>
			<xsl:if test="Dir/Dir">
			const int DirDirCount = <xsl:value-of select="Dir/Dir/@count"/>;
			string DirDirPaths[DirDirCount];
			Directory DirDirs[DirDirCount];
			int DirDDs[DirDirCount];
			</xsl:if>
			
			
			for ( int i = 0 ; i &lt; DirCount; ++i )
			{
				const int size = 10;
				char buf[size];
				Unres ( snprintf(buf, size, "%d", i) >= size, "Cannot prepare DirPath value.");
				
				DirPaths[i] = DirPrefix + buf;
				DirDs[i] = Dirs[i].Open(DirPaths[i], S_IRWXU);
				if ( DirDs[i] == -1 )
				{
					throw Exception("Directory descriptor is not valid.");
				}
			}
			
			<xsl:if test="Dir/File">
			for ( int i = 0 ; i &lt; DirFileCount; ++i )
			{
				const int size = 10;
				char buf[size];
				Unres ( snprintf(buf, size, "%d", i) >= size, "Cannot prepare DirFilePath value.");
				
				DirFilePaths[i] = DirPaths[0] + "/" + FilePrefix + buf;
				DirFDs[i] = DirFiles[i].Open(DirFilePaths[i], S_IRWXU, O_CREAT | O_RDWR);
				if ( DirFDs[i] == -1 )
				{
					throw Exception("File descriptor is not valid.");
				}
			}	
			</xsl:if>
			
			<xsl:if test="Dir/Dir">
			for ( int i = 0 ; i &lt; DirDirCount; ++i )
			{
				const int size = 10;
				char buf[size];
				Unres ( snprintf(buf, size, "%d", i) >= size, "Cannot prepare DirDirPath value.");
				
				DirDirPaths[i] = DirPaths[0] + "/" + DirPrefix + buf;
				DirDDs[i] = DirDirs[i].Open(DirDirPaths[i], S_IRWXU);
				if ( DirDDs[i] == -1 )
				{
					throw Exception("Dir descriptor is not valid.");
				}
			}	
			</xsl:if>
			
			</xsl:if>
			
			
			<xsl:if test="File">
			const int FileCount = <xsl:value-of select="File/@count"/>;
			int FileFlags = O_CREAT | O_RDWR;
			int FileMode = S_IRWXU;
			<xsl:if test="File/@flags != ''">
			FileFlags = <xsl:value-of select="File/@flags"/>;
			</xsl:if>
			<xsl:if test="File/@mode != ''">
			FileMode = <xsl:value-of select="File/@mode"/>;
			</xsl:if>
			string FilePaths[FileCount];
			File Files[FileCount];
			int FDs[FileCount];
			for ( int i = 0 ; i &lt; FileCount; ++i )
			{
				const int size = 10;
				char buf[size];
				Unres ( snprintf(buf, size, "%d", i) >= size, "Cannot prepare FilePath value.");
				
				FilePaths[i] = FilePrefix + buf;
				FDs[i] = Files[i].Open(FilePaths[i], FileMode, FileFlags);
				if ( FDs[i] == -1 )
				{
					throw Exception("File descriptor is not valid.");
				}
			}	
			</xsl:if>
			
			<xsl:value-of select="Code" />
			// This code should always be called!
			// Not allowed to use "return" statement in &lt;Code> segment.
			// Use Return(status) macro instead
		}
		catch (Exception e)
		{
			if ( PartitionManager::IsOptionEnabled("ro") &amp;&amp; e.GetErrno() == EROFS )
				Unsupp("Read only file system.");
			
			Error("Exception was thrown: ", e.GetMessage(), Unresolved);
		}
Footer: 
		_InFooter = true;
		<xsl:value-of select="Footer" />
		<xsl:value-of select="/TestSet/Footer" />	
		return _TestStatus;
	}
	</xsl:for-each>
protected:
	vector&lt;string> _tests_to_run;
	vector&lt;string> _tests_to_exclude;
	string _name;
	bool _fsim_enabled;
	string _fsim_point;
	string _fsim_expression;
	//const unsigned int _testCount;
	//const unsigned int _fsim_testCount;
	TestMap _tests;
	TestMap _fsim_tests;
	int _fault_count;
	//int (<xsl:value-of select="@Name" />Tests::*_tests[<xsl:value-of select="count(Test)"/>])(vector&lt;string>);
	//int (<xsl:value-of select="@Name" />Tests::*_fsim_tests[<xsl:value-of select="count(Test)"/>])(vector&lt;string>);
	vector&lt;FSimInfo> _fsim_info_vec;
	<xsl:value-of select="/TestSet/Internal"/>
	const string _DirPrefix;
	const string _FilePrefix;
	Status OopsChecker(string&amp; OutputLog)	
	{
		string mainMessage;
		vector&lt;string> args;
		args.push_back("-c"); // Clear the ring
		//args.push_back("dmesg");
		UnixCommand* command = new UnixCommand("dmesg");
		std::auto_ptr&lt;ProcessResult> result(command->Execute(args));
		if(result.get() == NULL || result->GetStatus() != Success)
		{
			OutputLog = "Unable to read system log";
			if ( result.get() != NULL )
				OutputLog += result->GetOutput();
			return Unresolved;
		}
		mainMessage = result->GetOutput();
		delete command;
		
		//searching points
		const string bug = "BUG";
		const string oops = "Oops";
		const string panic = "ernel panic";  //interested in both "Kernel panic" and "kernel panic"
		const char less = 60;  // 60 is the ASCII code of the operation 'less than'
		const char amp = 38;   // 38 is the ASCII code of the operation 'ampersand'
		size_t foundPos;
		
		foundPos = mainMessage.find(bug); // searching "bug" in the kernel output
		if( foundPos != string::npos )
		{
			OutputLog.assign(mainMessage.begin() + foundPos, mainMessage.end());
			size_t pos = 0;
			while(true)
			{
				pos = (OutputLog.find(amp, pos+1));
				if(pos == std::string::npos)
					break;
				OutputLog.replace(pos, 1, " "); 
			}
			while(true)
			{
				pos = (OutputLog.find(less, pos+1));
				if(pos == std::string::npos)
					break;
				OutputLog.replace(pos, 1, " ");   
			}
			cerr &lt;&lt; "Oops checker: bug found" &lt;&lt; endl;
			return Bug;
		}
		foundPos = mainMessage.find(oops);			
		if( foundPos != string::npos )
		{
			OutputLog.assign(mainMessage.begin() + foundPos, mainMessage.end());
			size_t pos = 0;
			while(true)
			{
				pos = (OutputLog.find(amp, pos+1));
				if(pos == std::string::npos)
					break;
				OutputLog.replace(pos, 1, " ");  
			}
			while(true)
			{
				pos = (OutputLog.find(less, pos+1));
				if(pos == std::string::npos)
					break;
				OutputLog.replace(pos, 1, " ");  
			}
			cerr &lt;&lt; "Oops checker: oops found" &lt;&lt; endl;
			return Oops;
		}
		foundPos = mainMessage.find(panic);			
		if( foundPos != string::npos )
		{
			OutputLog.assign(mainMessage.begin() + foundPos, mainMessage.end());
			size_t pos = 0;
			while(true)
			{
				pos = (OutputLog.find(amp, pos+1));
				if(pos == std::string::npos)
					break;
				OutputLog.replace(pos, 1, " ");  
			}
			while(true)
			{
				pos = (OutputLog.find(less, pos+1));
				if(pos == std::string::npos)
					break;
				OutputLog.replace(pos, 1, " ");  
			}
			cerr &lt;&lt; "Oops checker: Panic found" &lt;&lt; endl;
			return Panic;
		}
		return Success;
	}
};

<xsl:value-of select="GlobalFooter"/>
	</xsl:template>

</xsl:stylesheet>
