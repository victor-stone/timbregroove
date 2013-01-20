//
//  Sphere.m
//  TimbreGroove
//
//  Created by victor on 12/19/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Sphere.h"
#import "MeshBuffer.h"
#import "SphereOid.h"

@interface Sphere() {
    float _lightRot;
}
@end

@implementation Sphere

-(id)wireUp
{
    [super wireUp];
    if( !self.hasTexture )
        self.color = GLKVector4Make(0, 1, 0, 1);
    return self;
}


-(void)update:(NSTimeInterval)dt
{
    _lightRot += 0.03;
    GLKVector3 lDir = self.lightDir;
    GLKMatrix4 mx = GLKMatrix4MakeTranslation( lDir.x, lDir.y, lDir.z );
    
    mx = GLKMatrix4Rotate(mx, _lightRot, 0.0f, 1.0f, 0.0f);
    self.lightDir = GLKMatrix4MultiplyVector3(mx,GLKVector3Make(-1, 0, 0));
}

-(void)createBuffer
{
    NSArray * indiciesIntoNames;
    
    if( self.hasTexture )
    {
        indiciesIntoNames = @[@(gv_pos),   @(gv_uv),    @(gv_normal)];
    }
    else
    {
        indiciesIntoNames = @[@(gv_pos),   @(gv_normal)];
    }

    SphereOid * sp = [SphereOid sphereWithdIndicesIntoNames:indiciesIntoNames
                                                   andDoUVs:self.hasTexture
                                               andDoNormals:true];
    [self addBuffer:sp];
}
@end
