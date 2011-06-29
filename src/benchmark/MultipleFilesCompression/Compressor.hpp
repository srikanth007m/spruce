//      Compressor.hpp
//      
//      Copyright 2011 Eduard Bagrov <ebagrov@gmail.com>
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

#ifndef COMPRESSOR_H
#define COMPRESSOR_H

#include "BenchmarkTest.hpp"

// Operations
enum CompressOperations
{
	MultipleFilesCompression
};

class CompressTest : public BenchmarkTest
{
public:
		
	CompressTest(Mode m, int op, string a) : BenchmarkTest (m, op, a)
	{
		vector<string> arguments = ParseArguments(a);
		
		directory = arguments[0];
	}
		
	~CompressTest()
	{
	}
	
	int Main(vector<string>);
private:
	string directory;
	Status MultipleFilesCompressionFunc();
	vector<string> CreateArguments();};

#endif
