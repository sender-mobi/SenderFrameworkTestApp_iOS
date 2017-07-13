//
//  NSURL+PercentEscapes.m
//  SENDER
//
//  Created by Roman Serga on 01/6/16.
//  Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import "NSURL+PercentEscapes.m"

@implementation NSURL (PercentEscapes)

+ (instancetype)URLByAddingPercentEscapesToString:(NSString *)URLString
{
    if (!URLString) return nil;

    NSString * encodedString = [URLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return [NSURL URLWithString: encodedString];
}

@end
