//      Test.hpp
//      
//      Copyright (C) 2011, Institute for System Programming
//                          of the Russian Academy of Sciences (ISPRAS)
//      Author:
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

#ifndef TEST_BASE_H
#define TEST_BASE_H

#include "Common.hpp"
#include "Process.hpp"
#include <sstream>
#include <fstream>
using namespace std;

class TestResult : public ProcessResult
{
public:
	/*TestResult():
		ProcessResult(Unknown, "No output"),
		_operation(0),
		_arguments("No arguments provided") {}*/
	TestResult(ProcessResult pr, int op, string args):
		ProcessResult(pr),
		_operation(op),
		_stroperation(OperationToString()),
		_arguments(args) {}
	TestResult(Status s, string output, int op, string args):
		ProcessResult(s, output),
		_operation(op),
		_stroperation(OperationToString()),
		_arguments(args) {}
	TestResult(ProcessResult pr, string op, string args):
		ProcessResult(pr),
		_operation(0),
		_stroperation(op),		
		_arguments(args)
		 {}
	TestResult(Status s, string output, string op, string args):
		ProcessResult(s, output),
		_operation(0),
		_stroperation(op),
		_arguments(args) {}
	TestResult(TestResult const & tr) : 
		ProcessResult(tr),
		_operation(tr._operation),
		_stroperation(tr._stroperation),
		_arguments(tr._arguments) {}
	 	 	 
	virtual string ToXML();
	virtual string OperationToString()
	{
		return "Unknown";
		//return Operation::ToString((Operations)_operation);
	}
protected:
	int _operation;
	string _stroperation;
	string _arguments;

};

class TestResultCollection 
{
public:
	TestResultCollection():
		_results()
		{}
	void AddResult(Status s, string output, int op, string args)
	{
		TestResult * tmp = new TestResult(s,output,op,args);
		_results.push_back(tmp);
	}
	void AddResult(TestResult * result)
	{
		_results.push_back(result);
	}
	void Merge(TestResultCollection results)
	{
		for ( unsigned int i = 0; i < results._results.size(); )
		{
			_results.push_back(results._results[i]);
			// Erase the original pointer so that the destructors do not overlap
			results._results.erase(results._results.begin() + i);
		}
	}
	string ToXML()
	{
		string result = "";
		for ( vector<TestResult *>::iterator i = _results.begin(); i != _results.end(); ++i )
		{
			//cerr << (*i)->ToXML() << endl;
			result += (*i)->ToXML();			
		}
		
		return result;
	}
	// Returns the highest status in the collection.
	Status GetStatus()
	{
		Status max_stat = Success;
		for ( vector<TestResult *>::iterator i = _results.begin(); i != _results.end(); ++i )
			if ( (*i)->GetStatus() > max_stat && (*i)->GetStatus() >= Unresolved )
				max_stat = (*i)->GetStatus();
		return max_stat;
	}
	string GetOutput() const
	{
		return "asdf";
	}
	~TestResultCollection()
	{
		for ( vector<TestResult *>::iterator i = _results.begin(); i != _results.end(); ++i )
			delete (*i);
	}
private:
	vector<TestResult*> _results;
};

class Test : public Process
{
public:	
	Test(Mode m, int op, string a):
		_mode(m),
		_operation(op),
		_stroperation("Unknown"),
		_args(a) {}
	Test(Mode m, string op, string a):
		_mode(m),
		_operation(0),
		_stroperation(op),
		_args(a) {}
	Test(const Test & t):
		_mode(t._mode),
		_operation(t._operation),
		_stroperation(t._stroperation),
		_args(t._args) {}
	
	ProcessResult * Execute(vector<string> args = vector<string>());
	virtual ~Test() {}
protected:
	virtual int Main(vector<string> args) = 0;
	Mode _mode;
	int _operation;
	string _stroperation;
	string _args;
};

class TestCollection
{
public:
	TestResultCollection Run();
	void AddTest(Test * t)
	{
		_tests.push_back(t);
	}
	void Merge( TestCollection &);
	~TestCollection()
	{
		for ( vector<Test *>::iterator i = _tests.begin(); i != _tests.end(); ++i )
		{
			delete (*i);
		}
	}	
private:
	vector<Test *> _tests;
};

#endif /* TEST_BASE_H */