//
//  ViewController.m
//  accelerometer
//
//  Created by Jeremy Smith on 1/21/14.
//  Copyright (c) 2014 Jeremy Smith. All rights reserved.
//

#import "ViewController.h"

@interface ViewController (){
    CMMotionManager *motionManager;

    NSString *acceleromterString;
    NSString *gyroString;
    NSString *magnetometerString;
    
    NSMutableArray *accelerometerArr;
    NSMutableArray *gyroArr;
    NSMutableArray *magnetometerArr;
    
    float startTime;
    float stopTime;
}

@property (weak, nonatomic) IBOutlet UILabel *elapsedTimeLabel;

@end

@implementation ViewController

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (IBAction)stopButPressed:(id)sender {
    stopTime = CACurrentMediaTime();
    
    [motionManager stopAccelerometerUpdates];
    [motionManager stopGyroUpdates];
    [motionManager stopMagnetometerUpdates];
    
    NSLog(@"gyroCount: %d  accelerometerCount: %d magnetometerCount: %d", gyroArr.count, accelerometerArr.count, magnetometerArr.count);
    
    [self clearLabels];
    
    [self saveDataAndAddToEmail];
}

-(void)clearLabels{
    //clear labels
    self.elapsedTimeLabel.text = @"";
}

- (IBAction)startButPressed:(UIButton*)but {
    startTime = CACurrentMediaTime();
    
    acceleromterString = [[NSString alloc] init];
    gyroString = [[NSString alloc] init];
    magnetometerString = [[NSString alloc] init];
    
    accelerometerArr = [[NSMutableArray alloc] init];
    gyroArr = [[NSMutableArray alloc] init];
    magnetometerArr = [[NSMutableArray alloc] init];
    
    [self initializeMotionManager];
}

-(void)initializeMotionManager{
    motionManager = [[CMMotionManager alloc] init];
    motionManager.accelerometerUpdateInterval = .1;
    motionManager.gyroUpdateInterval = .1;
    motionManager.magnetometerUpdateInterval = .1;
    
    [motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMGyroData *gyroData, NSError *error){
        [self readGyroData:gyroData];
        if(error){
            NSLog(@"%@", error);
        }
    }];
    
    [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                        withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                            [self readAccelerationData:accelerometerData.acceleration];
                                            if(error){
                                                NSLog(@"%@", error);
                                            }
                                        }];
    
    [motionManager startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMMagnetometerData *magnetometerData, NSError *error){
        [self readMagnetometerData:magnetometerData];
        if(error){
            NSLog(@"%@", error);
        }
    }];
}


-(void)readAccelerationData:(CMAcceleration)acceleration{
    [accelerometerArr addObject:@""];
    
    self.elapsedTimeLabel.text = [NSString stringWithFormat:@"%f sec", CACurrentMediaTime() - startTime];
    
    acceleromterString = [acceleromterString stringByAppendingString:[NSString stringWithFormat:@"%f, %f, %f, %f \r\n", CACurrentMediaTime() - startTime, acceleration.x, acceleration.y, acceleration.z]];
}

-(void)readGyroData:(CMGyroData*)gyro{
    [gyroArr addObject:@""];
    
    gyroString = [acceleromterString stringByAppendingString:[NSString stringWithFormat:@"%f, %f, %f, %f \r\n", CACurrentMediaTime() - startTime , gyro.rotationRate.x, gyro.rotationRate.y, gyro.rotationRate.z]];
}

-(void)readMagnetometerData:(CMMagnetometerData*)magnetometer{
    [magnetometerArr addObject:@""];
    
    if (CACurrentMediaTime() - startTime >= 1) {
        [motionManager stopAccelerometerUpdates];
        [motionManager stopGyroUpdates];
        [motionManager stopMagnetometerUpdates];
        NSLog(@"%d", magnetometerArr.count);
    }
    
    magnetometerString = [magnetometerString stringByAppendingString:[NSString stringWithFormat:@"%f, %f, %f, %f \r\n", CACurrentMediaTime() - startTime , magnetometer.magneticField.x, magnetometer.magneticField.y, magnetometer.magneticField.z]];
}



////save and email methods
-(void)saveDataAndAddToEmail{
    NSString *accPath =  [self writeCSVToFile:@"accelerometer.txt" string:acceleromterString];
    NSString *magPath =  [self writeCSVToFile:@"magnetometer.txt" string:magnetometerString];
    NSString *gyroPath = [self writeCSVToFile:@"gyro.txt" string:gyroString];
    
    NSMutableDictionary *paths = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                 accPath, @"accelerometer.txt",
                                 magPath, @"magnetometer.txt",
                                 gyroPath, @"gyro.txt",
                                 nil];
    
    [self emailFilesWithPaths:paths];
}

-(NSString*)writeCSVToFile:(NSString*)file string:(NSString*)string{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *csvFilePath = [documentsDirectory stringByAppendingPathComponent:file];
    [string writeToFile:csvFilePath atomically:YES encoding:NSStringEncodingConversionAllowLossy error:nil];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    if ([fileManager fileExistsAtPath:csvFilePath isDirectory:NO]) {
        NSLog(@"%@", csvFilePath);
    }
    
    return csvFilePath;
}

-(void)emailFilesWithPaths:(NSMutableDictionary*)filePaths{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
        
    for (NSString *filePath in [filePaths allKeys]){
        NSMutableData *txtData = [NSMutableData dataWithContentsOfFile:[filePaths objectForKey:filePath]];
        [picker addAttachmentData:txtData mimeType:@"application/txt" fileName:filePath];
    }

    [self presentViewController:picker animated:YES completion:nil];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [self dismissViewControllerAnimated:YES completion:nil];
    if (result == MFMailComposeResultSent) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email Sent" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alert show];
    }
    else if (result == MFMailComposeResultFailed){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alert show];
    }
    else if (result == MFMailComposeResultCancelled){
        [self clearLabels];
    }
    
    
}

@end
