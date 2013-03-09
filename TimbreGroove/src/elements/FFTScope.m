//
//  FFTScope.m
//  TimbreGroove
//
//  Created by victor on 3/9/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Geometry.h"
#import "Line.h"
#import "SoundSystem.h"
#import "Parameter.h"
#import "Generic.h"

static int smbFft(float *fftBuffer, long fftFrameSize, long sign)
/*
 FFT routine, (C)1996 S.M.Bernsee. Sign = -1 is FFT, 1 is iFFT (inverse)
 Fills fftBuffer[0...2*fftFrameSize-1] with the Fourier transform of the
 time domain data in fftBuffer[0...2*fftFrameSize-1]. The FFT array takes
 and returns the cosine and sine parts in an interleaved manner, ie.
 fftBuffer[0] = cosPart[0], fftBuffer[1] = sinPart[0], asf. fftFrameSize
 must be a power of 2. It expects a complex input signal (see footnote 2),
 ie. when working with 'common' audio signals our input signal has to be
 passed as {in[0],0.,in[1],0.,in[2],0.,...} asf. In that case, the transform
 of the frequencies of interest is in fftBuffer[0...fftFrameSize].
 */
{
	float wr, wi, arg, *p1, *p2, temp;
	float tr, ti, ur, ui, *p1r, *p1i, *p2r, *p2i;
	long i, bitm, j, le, le2, k;
    
	for (i = 2; i < 2*fftFrameSize-2; i += 2) {
		for (bitm = 2, j = 0; bitm < 2*fftFrameSize; bitm <<= 1) {
			if (i & bitm) j++;
			j <<= 1;
		}
		if (i < j) {
			p1 = fftBuffer+i; p2 = fftBuffer+j;
			temp = *p1; *(p1++) = *p2;
			*(p2++) = temp; temp = *p1;
			*p1 = *p2; *p2 = temp;
		}
	}
	for (k = 0, le = 2; k < (long)(log(fftFrameSize)/log(2.)+.5); k++)
    {
		le <<= 1;
		le2 = le>>1;
		ur = 1.0;
		ui = 0.0;
		arg = M_PI / (le2>>1);
		wr = cos(arg);
		wi = sign*sin(arg);
		for (j = 0; j < le2; j += 2) {
			p1r = fftBuffer+j; p1i = p1r+1;
			p2r = p1r+le2; p2i = p2r+1;
			for (i = j; i < 2*fftFrameSize; i += le) {
				tr = *p2r * ur - *p2i * ui;
				ti = *p2r * ui + *p2i * ur;
				*p2r = *p1r - tr; *p2i = *p1i - ti;
				*p1r += tr; *p1i += ti;
				p1r += le; p1i += le;
				p2r += le; p2i += le;
			}
			tr = ur*wr - ui*wi;
			ui = ur*wi + ui*wr;
			ur = tr;
		}
	}
    
    return k;
//    NSLog(@"done fft");
}


@interface FFTScope : Generic {
    __weak Line * _lineMesh;
}


@end

@implementation FFTScope
-(void)createBuffer
{
    self.color = (GLKVector4){ 1, 1, 0.4, 1};
    Line * mesh = [[Line alloc] initWithIndicesIntoNames:@[@(gv_pos)]
                                               isDynamic:true
                                                 spacing:kFramesForDisplay];
    _lineMesh = mesh;
    [self addBuffer:mesh];
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[@"frameCapture"] = [Parameter withBlock:^(void *ptr) {
        if( ptr )
        {
            float _data[kFramesForDisplay*2];
            
            AudioBufferList * abl = (AudioBufferList *)ptr;
            float * p =  abl->mBuffers[0].mData;
            int n = 0;
            for( int i = 0; i < kFramesForDisplay; i++ )
            {
                _data[n++] = *p++;
                _data[n++] = 0.0;
            }
            smbFft(_data, kFramesForDisplay, 1 );
            _lineMesh.heightOffsets = _data;
            [_lineMesh resetVertices];
        }
    }];
}

@end
