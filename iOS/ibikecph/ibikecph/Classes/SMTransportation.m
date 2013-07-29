//
//  SMTransportation.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTransportation.h"
#import "SMTransportationLine.h"
#import "SMRelation.h"
#import "SMNode.h"
#import "SMWay.h"

#define CACHE_FILE_NAME @"StationsCached.data"
#define MAX_CONCURENT_ROUTE_THREADS 4

#define KEY_LINES @"KeyLines"

static NSOperationQueue* stationQueue;

@implementation SMTransportation{
    NSMutableArray* relations;
    SMRelation* relation;
    
    NSXMLParser* basicParser;
    NSXMLParser* detailsParser;
    
    NSMutableArray* allNodes;
    
    dispatch_queue_t queue;
}

+(SMTransportation*)instance{
    static SMTransportation* instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stationQueue= [[NSOperationQueue alloc] init];
        
        NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = [documentDirectories objectAtIndex:0];
        NSString *myFilePath = [documentDirectory stringByAppendingPathComponent:CACHE_FILE_NAME];
        
        instance= [NSKeyedUnarchiver unarchiveObjectWithFile:myFilePath];
        
        if(!instance){
            instance= [SMTransportation new];
        }

    });
    
    return instance;
}

-(id)init{
    if(self= [super init]){
        allNodes= [NSMutableArray new];
        queue= dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0L);
        
        dispatch_async(queue, ^{
            [self pullData];
        });

    }
    return self;
}

-(void)save{
    NSLog(@"SAVING...");
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory = [documentDirectories objectAtIndex:0];
	NSString *myFilePath = [documentDirectory stringByAppendingPathComponent:CACHE_FILE_NAME];
    
    [NSKeyedArchiver archiveRootObject:self toFile:myFilePath];
}

-(void)validateAndSave{
    for(SMTransportationLine* line in self.lines){
        for(SMStationInfo* sInfo in line.stations){
           if(![sInfo isValid])
                return;
        }
    }
    
    [self save];
}
- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.lines forKey:KEY_LINES];
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if(self=[super init]){
        self.lines= [aDecoder decodeObjectForKey:KEY_LINES];
    }
    return self;
}

+(NSOperationQueue*) transportationQueue{
    static NSOperationQueue * sRequestQueue;
    
    if(!sRequestQueue){
        sRequestQueue = [NSOperationQueue new];
        sRequestQueue.maxConcurrentOperationCount = MAX_CONCURENT_ROUTE_THREADS;
    }
    
    return sRequestQueue;
}

-(void) loadDummyData{
    NSString * filePath0 = [[NSBundle mainBundle] pathForResource:@"Albertslundruten" ofType:@"line"];
    NSString * filePath1 = [[NSBundle mainBundle] pathForResource:@"Farumruten" ofType:@"line"];
    SMTransportationLine * line0 = [[SMTransportationLine alloc] initWithFile:filePath0];
    SMTransportationLine * line1 = [[SMTransportationLine alloc] initWithFile:filePath1];

    self.lines = @[line0,line1];
}

-(void)didFinishFetchingStationData{
    [self initializeLines];
}

-(void)initializeLines{
    NSMutableArray* tempLines= [NSMutableArray new];
    for(SMRelation* rel in relations){

        [tempLines addObject:[[SMTransportationLine alloc] initWithRelation:rel]];
    }

    self.lines= [NSArray arrayWithArray:tempLines];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_STATIONS_FETCHED object:nil];
}

// http://overpass-api.de/api/interpreter?data=rel(50.745,7.17,50.75,7.18)[route=bus];out;
-(void)pullData{
    NSMutableURLRequest* req= [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://overpass-api.de/api/interpreter?data=rel(55,12,56,13)[route=bus];out;"]];

    [NSURLConnection sendAsynchronousRequest:req queue:stationQueue completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error){
        NSString* s= [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@",s);
        basicParser= [[NSXMLParser alloc] initWithData:data];
        basicParser.delegate= self;
        relations= [NSMutableArray new];
        [basicParser parse];

    }];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {

    if(parser==basicParser){
        if([elementName isEqualToString:@"relation"]){
            if(relation){
                [relations addObject:relation];
            }
            relation= [SMRelation new];
            return;
        }
        
        NSString* type= [attributeDict objectForKey:@"type"];
        NSString* role= [attributeDict objectForKey:@"role"];
        NSString* ref= [attributeDict objectForKey:@"ref"];
        if([type isEqualToString:@"way"]){
            SMWay* way= [SMWay new];
            way.ref= ref;
            way.role= role;
            [relation.ways addObject:way];
        }else if([type isEqualToString:@"node"]){
            NSArray* filteredNodes= [allNodes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.ref=%@",ref]];
            SMNode* node;
            if(filteredNodes.count>0){
                node= [filteredNodes objectAtIndex:0];
            }else{
                node= [SMNode new];
                node.ref= ref;
                node.role= role;
                [allNodes addObject:node];
            }
            
            [relation.nodes addObject:node];
        }
    }else if(parser==detailsParser){
        if([elementName isEqualToString:@"node"]){

            NSString* nodeID= [attributeDict objectForKey:@"id"];;

            NSNumber* lat= [attributeDict objectForKey:@"lat"];
            NSNumber* lng= [attributeDict objectForKey:@"lon"];
            
            NSArray* filteredNodes= [allNodes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.ref=%@",nodeID]];
            SMNode* node= nil;
            
            if (filteredNodes.count>0) {
                
                node= [filteredNodes objectAtIndex:0];
                NSLog(@"Setting %lf %lf for %@",lat.doubleValue, lng.doubleValue, nodeID);
                node.coordinate= CLLocationCoordinate2DMake(lat.doubleValue, lng.doubleValue);
            }
        }
    }
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser{
    if(parser==basicParser){
        [self fetchDetails];
    }else if(parser==detailsParser){
        [self didFinishFetchingStationData];
    }
}

-(void)fetchDetails{
    NSMutableURLRequest* req= [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[@"http://overpass-api.de/api/interpreter?data=rel(55,12,56,13)[route=bus];>;out;" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    
    [NSURLConnection sendAsynchronousRequest:req queue:stationQueue completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error){
        NSString* s= [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@",s);
        detailsParser= [[NSXMLParser alloc] initWithData:data];
        detailsParser.delegate= self;
      
        [detailsParser parse];

    }];
}

@end
