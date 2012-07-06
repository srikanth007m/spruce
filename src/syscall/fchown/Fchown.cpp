//      Chown.cpp
//      
//      Copyright (C) 2011, Institute for System Programming
//                          of the Russian Academy of Sciences (ISPRAS)
//      Author:
//			Gurgen Torozyan <gurgen.torozyan@gmail.com>
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

#include <Fchown.hpp>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include "File.hpp"
#include <pwd.h>




int Fchown::Main(vector<string>)
{
	if ( _mode == Normal )
	{	
		switch (_operation)
		{
			
			case FCHOWN_CHANGE_OWNER:
			return FchownTest();
			
		 /*   case CHOWN_ERR_ENAMETOOLONG:
				return  ChownTooLongPath();
			case FCHOWN_ERR_ENOENT:
				return  ChownFileNotExist();*/
		    case FCHOWN_ERR_EBADF:
				return FchownBadFd();
			default:
				cerr << "Unsupported operation.";
				return Unres;		
		}
	}
	cerr << "Test was successful";
	return Success;
}


Status Fchown::FchownTest()
{
	const char *path="fchownTest.txt";
	int ret_fchown;
	struct stat mode;
	struct passwd *nobody;
	int ret ;
	uid_t user_uid;
	gid_t user_gid;
	int fd;	
	try
	{
		File file(path, S_IWUSR);
		fd = file.GetFileDescriptor();

	   //getting struct for nobody user	
		nobody= getpwnam("nobody");
		if(nobody == NULL)
		{
			cerr << "getpwnam failed: Aborting test "<<strerror(errno);
			return Unres;
		}
		
		//getting user  and group id for nobody user.
		user_uid = nobody->pw_uid;
		user_gid = nobody->pw_gid;

		//changing owner  from root to nobody 
		ret_fchown = fchown(fd, user_uid,user_gid);
		
		if(ret_fchown == -1)
		{
			cerr << "Chown failed: Aborting test "<<strerror(errno);
			return Unres;
		}
			
			
		ret = stat(path, &mode);
		if( ret == -1 )
		{
				cerr << "stat failed: Aborting test "<<strerror(errno);
			return Unres;
		}
		
		if( user_uid != mode.st_uid )
		{
			cerr << "Chown failed :chown should chenge file owner from root to nobody but it does not";
			return Fail;	
		}
		
		if( user_gid != mode.st_gid )
		{
			cerr << "Chown failed :chown should chenge group  from root to nobody but it does not";
			return Fail;	
		}

		
		
		
		//ret_chown = chown(tooLongfilename, mode.st_uid,mode.st_gid);
	
	return Success;


	}
	
		catch (Exception ex)
	{
		cerr << ex.GetMessage();
		return Fail;
	}
}


Status Fchown::FchownBadFd()
{
	
	
	const char *path="fchownTest.txt";
	int ret_fchown;
	//struct stat mode;
	struct passwd *nobody;
	//int ret ;
	int user_uid;
	int user_gid;
	int fd;	
	
		File file(path, S_IWUSR);
		fd = file.GetFileDescriptor();

	   //getting struct for nobody user	
		nobody= getpwnam("nobody");
		if(nobody == NULL)
		{
			cerr << "getpwnam failed: Aborting test "<<strerror(errno);
			return Unres;
		}
		
		//getting user  and group id for nobody user.
		user_uid = nobody->pw_uid;
		user_gid = nobody->pw_gid;
		
	ret_fchown = fchown(-1, user_uid,user_gid);
	
	if(ret_fchown != -1)
		{
			cerr << "fchown should return -1 when the file descriptor is not vaild  "<<strerror(errno);
			return Fail;
		}
		
		else 
		{
			
			if(errno != EBADF)
			{
				
				cerr << "Incorrect error set in errno in case of bad file descriptor "<<strerror(errno);
				return Fail;
			}
			
		}
	return Success;
	
}



/*
Status Chown::ChownFileNotExist()
{
	
	const char *path="chownTest.txt";
	
	int ret_chown;
	ret_chown = chown(path, 0,0);
	
	if(ret_chown == 0)
	{
		cerr << "Chmod reruns 0 but it should return -1 when the file is not exist  "<<strerror(errno);
		return Fail;
	}
	else
		{
			
			if(errno != ENOENT)
			{
				
				cerr << "Incorrect error set in errno in case of file does not exists "<<strerror(errno);
				return Fail;
			}
		}
	
	return Success;
	
}

*/




	

