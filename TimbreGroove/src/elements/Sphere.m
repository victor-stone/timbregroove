//
//  Sphere.m
//  TimbreGroove
//
//  Created by victor on 12/19/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Sphere.h"
#import "MeshBuffer.h"

static void genSphere(TGGenericElementParams *p, float radius,
                      float lats, float longs, bool wNormals, bool wUV)
{

    size_t sz = sizeof(float) * 3 * lats * longs;
    if( wNormals )
        sz += (sizeof(float)*3);
    if( wUV )
        sz += (sizeof(float)*2);
}


@interface Sphere() {
    float _radius;
    float _longs;
    float _lats;
    float _lightRot;
}
@end

@implementation Sphere

-(id)wireUp
{
    if( !_radius )
        _radius = 1;
    if( !_longs )
        _longs = 30;
    if( !_lats )
        _lats = _longs;
    [super wireUp];
    if( !self.hasTexture )
        self.color = GLKVector4Make(0, 1, 0, 1);
    return self;
}

-(Sphere *)setRadius:(float)radius longs:(float)longs lats:(float)lats
{
    _radius = radius;
    _lats = lats;
    _longs = longs;
    
    self.color = GLKVector4Make(0, 1, 0, 1);
    return self;
}

-(Sphere *)setRadius:(float)radius longs:(float)longs lats:(float)lats textureFile:(const char *)fileName;
{
    _radius = radius;
    _lats = lats;
    _longs = longs;
    self.textureFileName = @(fileName);
    return self;
}

-(void)update:(NSTimeInterval)dt
{
    _lightRot += 0.03;
    GLKVector3 lDir = self.lightDir;
    GLKMatrix4 mx = GLKMatrix4MakeTranslation( lDir.x, lDir.y, lDir.z );
    
    mx = GLKMatrix4Rotate(mx, _lightRot, 1.0f, 0.0f, 0.0f);
    self.lightDir = GLKMatrix4MultiplyVector3(mx,GLKVector3Make(1, 0, -1));
}

-(void)createBuffer
{
    NSArray * types;

    if( self.hasTexture )
        types = @[@(sv_pos),@(sv_uv),@(sv_normal)];
    else
        types = @[@(sv_pos),@(sv_normal)];
    
    [self createBufferDataByType:types
                     numVertices:((_longs+1) * (_lats+1))
                      numIndices:_longs*_lats*6];
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned int *)indexData
{
    float * data = vertextData;
    bool wNormals = true;
    bool wUV = self.hasTexture;
    
	for (int latNumber = 0; latNumber <= _lats; ++latNumber) {
		for (int longNumber = 0; longNumber <= _longs; ++longNumber) {

			float theta = latNumber * M_PI / _lats;
			float phi = longNumber * 2 * M_PI / _longs;
			
			float sinTheta = sin(theta);
			float sinPhi = sin(phi);
			float cosTheta = cos(theta);
			float cosPhi = cos(phi);
			
			float x = cosPhi * sinTheta;
			float y = cosTheta;
			float z = sinPhi * sinTheta;
            
            *data++ = _radius * x;
            *data++ = _radius * y;
            *data++ = _radius * z;
			
            if( wNormals )
            {
                *data++ = x;
                *data++ = y;
                *data++ = z;
            }
            
            if( wUV )
            {
                float u = 1.0 - (1.0 * longNumber / _longs);
                float v = 1.0 * latNumber / _lats;
                *data++ = u;
                *data++ = v;
            }
		}
	}
    
    unsigned int * idata = indexData;
    
	for (int latNumber = 0; latNumber < _lats; latNumber++) {
		for (int longNumber = 0; longNumber < _longs; longNumber++) {
			
			int first = (latNumber * (_longs + 1)) + longNumber;
			int second = first + (_longs + 1);
			int third = first + 1;
			int fourth = second + 1;
			
            *idata++ = first;
            *idata++ = third;
            *idata++ = second;
            
            *idata++ = second;
            *idata++ = third;
            *idata++ = fourth;
		}
	}
    
}
@end