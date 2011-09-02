//      DupFileDescriptor.hpp
//
// 		Copyright (C) 2011, Institute for System Programming
//                          of the Russian Academy of Sciences (ISPRAS)
//
//      Authors: Shahzadyan Khachik <qwerity@gmail.com>
//                Ani Tumanyan <ani.tumanyan92@gmail.com>
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

#ifndef FCNTL_H
#define FCNTL_H

#include <fcntl.h>
#include "SyscallTest.hpp"

// Operations
enum fnctlFDSyscalls
{
	fcntlFDGetSetFileDescriptorFlags,
	fcntlFDGetSetFileStatusFlags,
	fcntlFDGetSetFileStatusFlagsIgnore,
	fcntlFDGetSetFileStatusFlagsIgnoreRDONLY,
	fcntlFDDupFileDescriptor,
	fcntlFDGetLock,
	fcntlFDSetLock,
	fcntlFDSetLockWithWait, 
	fcntlFDNoteDir,
	fcntlFDNoteFile, 
	fcntlFDBadFileDescriptor1,
	fcntlFDBadFileDescriptor2,
	fcntlFDTooManyOpenedFiles,
	fcntlFDGetSetLease,
	fcntlFDInvalidArg1,
	fcntlFDInvalidArg2,
	fcntlFDInvalidArg3,
	fcntlFDGetSetOwn, 
	fcntlFDBadAdress,
	fcntlFDResTempUnavailable,
	fcntlFDNoLock,
    fcntlFDGetSetSig,
    fcntlFDGetSetOwn_Ex
};

class fcntlFD : public SyscallTest
{
	public:
		fcntlFD(Mode mode, int operation, string arguments = "") :
			SyscallTest(mode, operation, arguments, "fcntl"){}
		virtual ~fcntlFD() {}

	// Test Functions
		Status get_setFileDescriptorFlags();
		Status get_setFileStatusFlags();
		Status get_setFileStatusFlagsIgnore();
		Status get_setFileStatusFlagsIgnoreRDONLY();
		Status dupFileDescriptor();
		Status fcntlFDGetLockFunction();
		Status fcntlFDSetLockFunction();
        Status fcntlFDSetLockWithWaitFunction();
        Status fcntlFDNoteFileFunction();
        Status fcntlFDNoteDirFunction();
        Status fcntlFDBadFileDescriptor1Func();
	    Status fcntlFDBadFileDescriptor2Func();
        Status fcntlFDTooManyOpenedFilesFunc();
        Status fcntlFDGetSetLeaseFunc();
        Status fcntlFDInvalidArg1Func();
        Status fcntlFDInvalidArg2Func();
        Status fcntlFDInvalidArg3Func();
        Status fcntlFDGetSetOwnFunc();
        Status fcntlFDBadAdressFunc();
        Status fcntlFDResTempUnavailableFunc();
        Status fcntlFDGetSetSigFunc();
        Status fcntlFDNoLockFunction();
        Status fcntlFDGetSetOwn_ExFunc();
        
	protected:
		virtual int Main(vector<string> args);
};

#endif /* FCNTL_H */
