//
//  GameScene.m
//  SKInvaders
//

//  Copyright (c) 2013 RepublicOfApps, LLC. All rights reserved.
//

#import "GameScene.h"
#import <CoreMotion/CoreMotion.h>

#pragma mark - Custom Type Definitions
static const u_int32_t kInvaderCategory            = 0x1 << 0;
static const u_int32_t kShipFiredBulletCategory    = 0x1 << 1;
static const u_int32_t kShipCategory               = 0x1 << 2;
static const u_int32_t kSceneEdgeCategory          = 0x1 << 3;
static const u_int32_t kInvaderFiredBulletCategory = 0x1 << 4;

//1
typedef enum InvaderType {
    InvaderTypeA,
    InvaderTypeB,
    InvaderTypeC
} InvaderType;

typedef enum InvaderMovementDirection {
    InvaderMovementDirectionRight,
    InvaderMovementDirectionLeft,
    InvaderMovementDirectionDownThenRight,
    InvaderMovementDirectionDownThenLeft,
    InvaderMovementDirectionNone
} InvaderMovementDirection;

typedef enum BulletType {
    ShipFiredBulletType,
    InvaderFiredBulletType
} BulletType;

//2
#define kInvaderSize CGSizeMake(24, 16)
#define kInvaderGridSpacing CGSizeMake(12, 12)
#define kInvaderRowCount 6
#define kInvaderColCount 6
//3
#define kInvaderName @"invader"
#define kShipSize CGSizeMake(30, 16)
#define kShipName @"ship"
#define kScoreHudName @"scoreHud"
#define kHealthHudName @"healthHud"

#define kShipFiredBulletName @"shipFiredBullet"
#define kInvaderFiredBulletName @"invaderFiredBullet"
#define kBulletSize CGSizeMake(4, 8)

#pragma mark - Private GameScene Properties

@interface GameScene ()
    @property BOOL contentCreated;
    @property InvaderMovementDirection invaderMovementDirection;
    @property NSTimeInterval timeOfLastMove;
    @property NSTimeInterval timePerMove;
    @property (strong) CMMotionManager* motionManager;
    @property (strong) NSMutableArray* tapQueue;
    @property (strong) NSMutableArray* contactQueue;
@end


@implementation GameScene

#pragma mark Object Lifecycle Management

#pragma mark - Scene Setup and Content Creation

-(SKNode*)makeBulletOfType:(BulletType)bulletType {
    SKNode* bullet;
    
    switch (bulletType) {
        case ShipFiredBulletType:
            bullet = [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:kBulletSize];
            bullet.name = kShipFiredBulletName;
            bullet.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:bullet.frame.size];
            bullet.physicsBody.dynamic = YES;
            bullet.physicsBody.affectedByGravity = NO;
            bullet.physicsBody.categoryBitMask = kShipFiredBulletCategory;
            bullet.physicsBody.contactTestBitMask = kInvaderCategory;
            bullet.physicsBody.collisionBitMask = 0x0;
            break;
        case InvaderFiredBulletType:
            bullet = [SKSpriteNode spriteNodeWithColor:[SKColor magentaColor] size:kBulletSize];
            bullet.name = kInvaderFiredBulletName;
            bullet.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:bullet.frame.size];
            bullet.physicsBody.dynamic = YES;
            bullet.physicsBody.affectedByGravity = NO;
            bullet.physicsBody.categoryBitMask = kInvaderFiredBulletCategory;
            bullet.physicsBody.contactTestBitMask = kShipCategory;
            bullet.physicsBody.collisionBitMask = 0x0;
            break;
        default:
            bullet = nil;
            break;
    }
    
    return bullet;
}

- (void)didMoveToView:(SKView *)view
{
    if (!self.contentCreated) {
        [self createContent];
        self.contentCreated = YES;
        self.motionManager = [[CMMotionManager alloc] init];
        [self.motionManager startAccelerometerUpdates];
        self.tapQueue = [NSMutableArray array];
        self.userInteractionEnabled = YES;
        self.contactQueue = [NSMutableArray array];
        self.physicsWorld.contactDelegate = self;
    }
}

- (void)createContent
{
    /*
    SKSpriteNode* invader = [SKSpriteNode spriteNodeWithImageNamed:@"InvaderA_00.png"];
    invader.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:invader];
    */
    //1
    self.invaderMovementDirection = InvaderMovementDirectionRight;
    //2
    self.timePerMove = 1.0;
    //3
    self.timeOfLastMove = 0.0;
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsBody.categoryBitMask = kSceneEdgeCategory;
    [self setupInvaders];
    [self setupShip];
    [self setupHud];
}

-(SKNode*)makeInvaderOfType:(InvaderType)invaderType {
    //1
    SKColor* invaderColor;
    switch (invaderType) {
        case InvaderTypeA:
            invaderColor = [SKColor redColor];
            break;
        case InvaderTypeB:
            invaderColor = [SKColor greenColor];
            break;
        case InvaderTypeC:
        default:
            invaderColor = [SKColor blueColor];
            break;
    }
    
    //2
    SKSpriteNode* invader = [SKSpriteNode spriteNodeWithColor:invaderColor size:kInvaderSize];
    invader.name = kInvaderName;
    
    invader.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:invader.frame.size];
    invader.physicsBody.dynamic = NO;
    invader.physicsBody.categoryBitMask = kInvaderCategory;
    invader.physicsBody.contactTestBitMask = 0x0;
    invader.physicsBody.collisionBitMask = 0x0;
    
    return invader;
}

-(void)setupInvaders {
    //1
    CGPoint baseOrigin = CGPointMake(kInvaderSize.width / 2, 180);
    for (NSUInteger row = 0; row < kInvaderRowCount; ++row) {
        //2
        InvaderType invaderType;
        if (row % 3 == 0)      invaderType = InvaderTypeA;
        else if (row % 3 == 1) invaderType = InvaderTypeB;
        else                   invaderType = InvaderTypeC;
        
        //3
        CGPoint invaderPosition = CGPointMake(baseOrigin.x, row * (kInvaderGridSpacing.height + kInvaderSize.height) + baseOrigin.y);
        
        //4
        for (NSUInteger col = 0; col < kInvaderColCount; ++col) {
            //5
            SKNode* invader = [self makeInvaderOfType:invaderType];
            invader.position = invaderPosition;
            [self addChild:invader];
            //6
            invaderPosition.x += kInvaderSize.width + kInvaderGridSpacing.width;
        }
    }
}

-(void)setupShip {
    //1
    SKNode* ship = [self makeShip];
    //2
    ship.position = CGPointMake(self.size.width / 2.0f, kShipSize.height/2.0f);
    [self addChild:ship];
}

-(SKNode*)makeShip {
    SKNode* ship = [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:kShipSize];
    ship.name = kShipName;
    
    //1
    ship.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:ship.frame.size];
    //2
    ship.physicsBody.dynamic = YES;
    //3
    ship.physicsBody.affectedByGravity = NO;
    //4
    ship.physicsBody.mass = 0.02;
    
    //1
    ship.physicsBody.categoryBitMask = kShipCategory;
    //2
    ship.physicsBody.contactTestBitMask = 0x0;
    //3
    ship.physicsBody.collisionBitMask = kSceneEdgeCategory;
    
    return ship;
}

-(void)setupHud {
    SKLabelNode* scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
    //1
    scoreLabel.name = kScoreHudName;
    scoreLabel.fontSize = 15;
    //2
    scoreLabel.fontColor = [SKColor greenColor];
    scoreLabel.text = [NSString stringWithFormat:@"Score: %04u", 0];
    //3
    scoreLabel.position = CGPointMake(20 + scoreLabel.frame.size.width/2, self.size.height - (20 + scoreLabel.frame.size.height/2));
    [self addChild:scoreLabel];
    
    SKLabelNode* healthLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
    //4
    healthLabel.name = kHealthHudName;
    healthLabel.fontSize = 15;
    //5
    healthLabel.fontColor = [SKColor redColor];
    healthLabel.text = [NSString stringWithFormat:@"Health: %.1f%%", 100.0f];
    //6
    healthLabel.position = CGPointMake(self.size.width - healthLabel.frame.size.width/2 - 20, self.size.height - (20 + healthLabel.frame.size.height/2));
    [self addChild:healthLabel];
}

#pragma mark - Scene Update

-(void)update:(NSTimeInterval)currentTime {
    [self processContactsForUpdate:currentTime];
    [self processUserTapsForUpdate:currentTime];
    [self processUserMotionForUpdate:currentTime];
    [self moveInvadersForUpdate:currentTime];
    [self fireInvaderBulletsForUpdate:currentTime];
}

#pragma mark - Scene Update Helpers

// This method will get invoked by update:
-(void)moveInvadersForUpdate:(NSTimeInterval)currentTime {
    //1
    if (currentTime - self.timeOfLastMove < self.timePerMove) return;
    [self determineInvaderMovementDirection];
    
    //2
    [self enumerateChildNodesWithName:kInvaderName usingBlock:^(SKNode *node, BOOL *stop) {
        switch (self.invaderMovementDirection) {
            case InvaderMovementDirectionRight:
                node.position = CGPointMake(node.position.x + 10, node.position.y);
                break;
            case InvaderMovementDirectionLeft:
                node.position = CGPointMake(node.position.x - 10, node.position.y);
                break;
            case InvaderMovementDirectionDownThenLeft:
            case InvaderMovementDirectionDownThenRight:
                node.position = CGPointMake(node.position.x, node.position.y - 10);
                break;
            InvaderMovementDirectionNone:
            default:
                break;
        }
    }];
    
    //3
    self.timeOfLastMove = currentTime;
}

-(void)processUserTapsForUpdate:(NSTimeInterval)currentTime {
    //1
    for (NSNumber* tapCount in [self.tapQueue copy]) {
        if ([tapCount unsignedIntegerValue] == 1) {
            //2
            [self fireShipBullets];
        }
        //3
        [self.tapQueue removeObject:tapCount];
    }
}

-(void)processUserMotionForUpdate:(NSTimeInterval)currentTime {
    //1
    SKSpriteNode* ship = (SKSpriteNode*)[self childNodeWithName:kShipName];
    //2
    CMAccelerometerData* data = self.motionManager.accelerometerData;
    //3
    if (fabs(data.acceleration.x) > 0.2) {
        //4 How do you move the ship?
        [ship.physicsBody applyForce:CGVectorMake(40.0 * data.acceleration.x, 0)];
    }
}

-(void)fireInvaderBulletsForUpdate:(NSTimeInterval)currentTime {
    SKNode* existingBullet = [self childNodeWithName:kInvaderFiredBulletName];
    //1
    if (!existingBullet) {
        //2
        NSMutableArray* allInvaders = [NSMutableArray array];
        [self enumerateChildNodesWithName:kInvaderName usingBlock:^(SKNode *node, BOOL *stop) {
            [allInvaders addObject:node];
        }];
        
        if ([allInvaders count] > 0) {
            //3
            NSUInteger allInvadersIndex = arc4random_uniform([allInvaders count]);
            SKNode* invader = [allInvaders objectAtIndex:allInvadersIndex];
            //4
            SKNode* bullet = [self makeBulletOfType:InvaderFiredBulletType];
            bullet.position = CGPointMake(invader.position.x, invader.position.y - invader.frame.size.height/2 + bullet.frame.size.height / 2);
            //5
            CGPoint bulletDestination = CGPointMake(invader.position.x, - bullet.frame.size.height / 2);
            //6
            [self fireBullet:bullet toDestination:bulletDestination withDuration:2.0 soundFileName:@"InvaderBullet.wav"];
        }
    }
}

-(void)processContactsForUpdate:(NSTimeInterval)currentTime {
    for (SKPhysicsContact* contact in [self.contactQueue copy]) {
        [self handleContact:contact];
        [self.contactQueue removeObject:contact];
    }
}

#pragma mark - Invader Movement Helpers

-(void)determineInvaderMovementDirection {
    //1
    __block InvaderMovementDirection proposedMovementDirection = self.invaderMovementDirection;
    
    //2
    [self enumerateChildNodesWithName:kInvaderName usingBlock:^(SKNode *node, BOOL *stop) {
        switch (self.invaderMovementDirection) {
            case InvaderMovementDirectionRight:
                //3
                if (CGRectGetMaxX(node.frame) >= node.scene.size.width - 1.0f) {
                    proposedMovementDirection = InvaderMovementDirectionDownThenLeft;
                    *stop = YES;
                }
                break;
            case InvaderMovementDirectionLeft:
                //4
                if (CGRectGetMinX(node.frame) <= 1.0f) {
                    proposedMovementDirection = InvaderMovementDirectionDownThenRight;
                    *stop = YES;
                }
                break;
            case InvaderMovementDirectionDownThenLeft:
                //5
                proposedMovementDirection = InvaderMovementDirectionLeft;
                *stop = YES;
                break;
            case InvaderMovementDirectionDownThenRight:
                //6
                proposedMovementDirection = InvaderMovementDirectionRight;
                *stop = YES;
                break;
            default:
                break;
        }
    }];
    
    //7
    if (proposedMovementDirection != self.invaderMovementDirection) {
        self.invaderMovementDirection = proposedMovementDirection;
    }
}

#pragma mark - Bullet Helpers
-(void)fireBullet:(SKNode*)bullet toDestination:(CGPoint)destination withDuration:(NSTimeInterval)duration soundFileName:(NSString*)soundFileName {
    //1
    SKAction* bulletAction = [SKAction sequence:@[[SKAction moveTo:destination duration:duration],
                                                  [SKAction waitForDuration:3.0/60.0],
                                                  [SKAction removeFromParent]]];
    //2
    SKAction* soundAction  = [SKAction playSoundFileNamed:soundFileName waitForCompletion:YES];
    //3
    [bullet runAction:[SKAction group:@[bulletAction, soundAction]]];
    //4
    [self addChild:bullet];
}

-(void)fireShipBullets {
    SKNode* existingBullet = [self childNodeWithName:kShipFiredBulletName];
    //1
    if (!existingBullet) {
        SKNode* ship = [self childNodeWithName:kShipName];
        SKNode* bullet = [self makeBulletOfType:ShipFiredBulletType];
        //2
        bullet.position = CGPointMake(ship.position.x, ship.position.y + ship.frame.size.height - bullet.frame.size.height / 2);
        //3
        CGPoint bulletDestination = CGPointMake(ship.position.x, self.frame.size.height + bullet.frame.size.height / 2);
        //4
        [self fireBullet:bullet toDestination:bulletDestination withDuration:1.0 soundFileName:@"ShipBullet.wav"];
    }
}

#pragma mark - User Tap Helpers
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // Intentional no-op
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    // Intentional no-op
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    // Intentional no-op
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch* touch = [touches anyObject];
    if (touch.tapCount == 1) [self.tapQueue addObject:@1];
}

#pragma mark - HUD Helpers

#pragma mark - Physics Contact Helpers
-(void)didBeginContact:(SKPhysicsContact *)contact {
    [self.contactQueue addObject:contact];
}

-(void)handleContact:(SKPhysicsContact*)contact {
    //1
    // Ensure you haven't already handled this contact and removed its nodes
    if (!contact.bodyA.node.parent || !contact.bodyB.node.parent) return;
    
    NSArray* nodeNames = @[contact.bodyA.node.name, contact.bodyB.node.name];
    if ([nodeNames containsObject:kShipName] && [nodeNames containsObject:kInvaderFiredBulletName]) {
        //2
        // Invader bullet hit a ship
        [self runAction:[SKAction playSoundFileNamed:@"ShipHit.wav" waitForCompletion:NO]];
        [contact.bodyA.node removeFromParent];
        [contact.bodyB.node removeFromParent];
    } else if ([nodeNames containsObject:kInvaderName] && [nodeNames containsObject:kShipFiredBulletName]) {
        //3
        // Ship bullet hit an invader
        [self runAction:[SKAction playSoundFileNamed:@"InvaderHit.wav" waitForCompletion:NO]];
        [contact.bodyA.node removeFromParent];
        [contact.bodyB.node removeFromParent];
    }
}

#pragma mark - Game End Helpers

@end
