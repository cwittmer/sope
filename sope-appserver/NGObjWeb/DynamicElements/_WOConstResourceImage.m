/*
  Copyright (C) 2000-2005 SKYRIX Software AG

  This file is part of SOPE.

  SOPE is free software; you can redistribute it and/or modify it under
  the terms of the GNU Lesser General Public License as published by the
  Free Software Foundation; either version 2, or (at your option) any
  later version.

  SOPE is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
  License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with SOPE; see the file COPYING.  If not, write to the
  Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
  02111-1307, USA.
*/

#include "WOImage.h"

@interface _WOConstResourceImage : WOImage
{
  NSString *filename;  // path relative to WebServerResources
}
@end

#include "WOElement+private.h"
#include <NGObjWeb/WOApplication.h>
#include <NGObjWeb/WOResourceManager.h>
#include "decommon.h"

@implementation _WOConstResourceImage

static BOOL debugOn = NO;

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    WOAssociation *tmp;

    tmp = OWGetProperty(_config, @"filename");
    self->filename  = [[tmp stringValueInComponent:nil] copy];
    [tmp release];
    
    if (self->filename == nil) {
      NSLog(@"missing filename association for WOImage ..");
      [self release];
      return nil;
    }

#if DEBUG
    if ([_config objectForKey:@"value"]    ||
        [_config objectForKey:@"data"]     ||
        [_config objectForKey:@"mimeType"] ||
        [_config objectForKey:@"key"]      ||
        [_config objectForKey:@"src"]) {
      NSLog(@"WARNING: inconsistent association settings in WOImage !"
            @" (assign only one of value, src, data or filename)");
    }
#endif
  }
  return self;
}

- (void)dealloc {
  [self->filename release];
  [super dealloc];
}

/* HTML generation */

- (void)_appendSrcToResponse:(WOResponse *)_resp inContext:(WOContext *)_ctx {
  WOComponent *sComponent;
  NSString    *uFi;
  NSArray     *languages;
  WOResourceManager *rm;
  NSString    *frameworkName;
  
  sComponent = [_ctx component];
  
  if (self->filename == nil) {
    [_resp appendContentHTMLAttributeValue:
             @"/missingImage?reason=nilfilenamebinding"];
    [self debugWithFormat:@"missing 'filename' binding value ..."];
    return;
  }
  
  /* this has no measurable effect on performance ... */
  if ((rm = [[_ctx component] resourceManager]) == nil)
    rm = [[_ctx application] resourceManager];
  
  languages = [_ctx resourceLookupLanguages];

  if (debugOn) {
    [self debugWithFormat:@"WOImage: filename '%@'\n  rm %@\n  languages %@",
	    self->filename, rm, [languages componentsJoinedByString:@","]];
  }
  
  /* 
     'framework' binding is not set in that case -> use parent component's 
     framework 
  */
  frameworkName = [[_ctx component] frameworkName];
  uFi = [rm urlForResourceNamed:self->filename
            inFramework:frameworkName 
            languages:languages
            request:[_ctx request]];
  if (uFi == nil) {
    [self logWithFormat:
	    @"%@: did not find resource '%@'", sComponent, self->filename];
    uFi = [@"/missingImage?" stringByAppendingString:self->filename];
  }
  
  if (debugOn)
    [self debugWithFormat:@"WOImage: constant resource URL: '%@'", uFi];
  
  [_resp appendContentHTMLAttributeValue:uFi];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

/* description */

- (NSString *)associationDescription {
  NSMutableString *str = [NSMutableString stringWithCapacity:64];
  
  [str appendFormat:@" filename=%@", self->filename];
  [str appendString:[super associationDescription]];
  return str;
}

@end /* _WOConstResourceImage */
