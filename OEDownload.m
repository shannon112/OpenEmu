/*
 Copyright (c) 2009, OpenEmu Team
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of the OpenEmu Team nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "OEDownload.h"
#import "GameDocumentController.h"
#import <Sparkle/Sparkle.h>
#import <XADMaster/XADArchive.h>

@implementation OEDownload

@synthesize enabled, appcastItem, progress, progressBar;

// FIXME: is that relevant ?
- (id)init
{
	if( self = [super init] )
	{
		enabled = YES;
		downloadedSize = 0;
		expectedLength = 1;
		progress = 0.0;
		progressBar = [[NSProgressIndicator alloc] init];
		[progressBar setControlSize:NSMiniControlSize];
		[progressBar setMinValue:0.0];
		[progressBar setMaxValue:1.0];
		[progressBar setStyle: NSProgressIndicatorBarStyle];
		[progressBar setIndeterminate:NO];
	//	NSLog(@"%@", [appcastItem propertiesDictionary]);
	}
	return self;
}

- (id) copyWithZone:(NSZone*) zone
{
	return [self retain];
}

- (id)initWithAppcast:(SUAppcast *)appcast
{
    if(self = [super init])
    {
        enabled = YES;
        
        //Assuming 0 is the best download, may or may not be the best
        self.appcastItem = [[appcast items] objectAtIndex:0];
        //NSLog(@"%@", [appcastItem propertiesDictionary]);
    }
    return self;
}

- (void) startDownload
{
	NSURLRequest *request = [NSURLRequest requestWithURL:[appcastItem fileURL]];
	NSURLDownload *fileDownload = [[[NSURLDownload alloc] initWithRequest:request delegate:self] autorelease];
	
	if( !fileDownload )
		NSLog(@"Couldn't download!??");
}


- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{	
    downloadPath = [[NSString stringWithCString:tmpnam(nil) 
										   encoding:[NSString defaultCStringEncoding]] retain];
	
    [download setDestination:downloadPath allowOverwrite:NO];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    // release the connection
    [download release];
	
    // inform the user
    NSLog(@"Download failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void) download: (NSURLDownload*)download didCreateDestination: (NSString*)path
{
	//  NSLog(@"%@",@"created dest");
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
	downloadedSize += length;
	progress =  (double) downloadedSize /  (double) expectedLength;
//	NSLog(@"Got data:%f", (double) downloadedSize /  (double) expectedLength);
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	expectedLength = [response expectedContentLength];
	NSLog(@"Got response");
}

- (void)downloadDidFinish:(NSURLDownload *)download
{	
	XADArchive* archive = [XADArchive archiveForFile:downloadPath];
	
	NSString* appsupportFolder = [[GameDocumentController sharedDocumentController] applicationSupportFolder];
	appsupportFolder = [appsupportFolder stringByAppendingPathComponent:@"Cores"];
	[archive extractTo:appsupportFolder];
	
    // release the connection
    [download release];
	
    // do something with the data
	// NSLog(@"downloadDidFinish to path %@",path);
	
	[[NSFileManager defaultManager] removeFileAtPath:downloadPath handler:nil];
}

- (NSString *)name
{
    return [appcastItem title];
}
@end
