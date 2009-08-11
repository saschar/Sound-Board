//
//  AppController.m
//  Soundboard
//
//  Created by Sascha Rank on 09.08.09.
//  
//Copyright (c) <2009> <Sascha Rank>

//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in
//all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//THE SOFTWARE.


#import "AppController.h"
#import "Sound.h"



OSStatus hotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData);

NSString * const needsCmdKey = @"needsCmdKey";
NSString * const needsOptionKey = @"needsOptionKey";

@implementation AppController

+ (void) initialize
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setObject: [NSNumber numberWithBool:NO] forKey: needsCmdKey];
	[defaultValues setObject: [NSNumber numberWithBool:NO] forKey: needsOptionKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (void) awakeFromNib
{
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	managedObjectContext = [appDelegate managedObjectContext];
	fetchRequest.entity = [NSEntityDescription entityForName:@"Sound" inManagedObjectContext: managedObjectContext];
	soundItems = [managedObjectContext executeFetchRequest: fetchRequest error: nil];
	
	if ([soundItems count] != 12) {
		int i;
		for (i = 0; i +1 <= [soundItems count]; i++) {
			[managedObjectContext deleteObject: [soundItems objectAtIndex:i]];
		}
		for (i = 1; i <= 12; i++) {
			Sound *newSoundItem = (Sound *)[[[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Sound" inManagedObjectContext:managedObjectContext] insertIntoManagedObjectContext:managedObjectContext]retain];
			newSoundItem.fKeyIndex = [NSNumber numberWithInt:i];
		}
		[managedObjectContext save:nil];
		soundItems = [managedObjectContext executeFetchRequest: fetchRequest error: nil];
		} 
	[tableView reloadData];
	[fetchRequest release];
	NSLog(@"%d ", [soundItems count]);
	
	BOOL cmdNeeded = [[NSUserDefaults standardUserDefaults] boolForKey:needsCmdKey];
	BOOL optionNeeded = [[NSUserDefaults standardUserDefaults] boolForKey:needsOptionKey];
	
	EventTypeSpec eventType;
	eventType.eventClass=kEventClassKeyboard;
	eventType.eventKind=kEventHotKeyPressed;
	InstallApplicationEventHandler(&hotKeyHandler,1,&eventType,self,NULL);
	int i;
		int keyID;
	    for (i = 1; i <= 12; i++) {
			EventHotKeyRef hotKeyRef;
		    EventHotKeyID hotKeyID;
			hotKeyID.signature = 'mhk1';
			hotKeyID.id = i;
			switch (i) {
				case 1:
					keyID = 122;
					break;
				case 2:
					keyID = 120;
					break;
				case 3:
					keyID = 99;
					break;
				case 4:
					keyID = 118;
					break;
				case 5:
					keyID = 96;
					break;
				case 6:
					keyID = 97;
					break;
				case 7:
					keyID = 98;
					break;
				case 8:
					keyID = 100;
					break;
				case 9:
					keyID = 101;
					break;
				case 10:
					keyID = 109;
					break;
				case 11:
					keyID = 103; 
					break;
				case 12:
					keyID = 111;
					break;
			}
			if (cmdNeeded && optionNeeded)
				RegisterEventHotKey(keyID, cmdKey + optionKey, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
			else if (cmdNeeded)
				RegisterEventHotKey(keyID, cmdKey, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
			else if (optionNeeded)
				RegisterEventHotKey(keyID, optionKey, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
			else 
				RegisterEventHotKey(keyID, 0, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
		}
}

OSStatus hotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData)
{
	EventHotKeyID hotKeyReference;
	
	GetEventParameter(anEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hotKeyReference), NULL, &hotKeyReference);
	
	AppController *self = (AppController *) userData;
	[self playSoundForIndex:hotKeyReference.id -1];
	
	
	return noErr;
}


- (void) playSoundForIndex:(int) index
{
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]  initWithKey:@"fKeyIndex.intValue" ascending:YES];
	fetchRequest.sortDescriptors = [NSArray arrayWithObject: sortDescriptor];
	fetchRequest.entity = [NSEntityDescription entityForName:@"Sound" inManagedObjectContext: managedObjectContext];

	soundItems = [managedObjectContext executeFetchRequest: fetchRequest error: nil];
	Sound *sound = (Sound *)[soundItems objectAtIndex:index];
	if ([soundPlayer isPlaying]) 
		[soundPlayer stop];
	soundPlayer = [[NSSound alloc] initWithContentsOfURL:[sound soundFilePath] byReference:YES];
	soundPlayer.volume = 1;
	[soundPlayer play];
	[soundPlayer release];
	[fetchRequest release];
	[sortDescriptor release];
}

- (NSArray *) sortDescriptors
{
	return [NSArray arrayWithObject:[[NSSortDescriptor alloc]  initWithKey:@"fKeyIndex.intValue" ascending:YES]];
}

- (NSManagedObjectContext *) managedObjectContext
{
	managedObjectContext = [appDelegate managedObjectContext];
	return managedObjectContext;
}

- (IBAction) showPreferences:(id)sender
{
	[preferenceController showWindow:self];
}


@end
