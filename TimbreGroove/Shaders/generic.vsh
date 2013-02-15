//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
//
precision highp float;

attribute vec4 a_position;

#ifdef TEXTURE
attribute vec2 a_uv;
varying lowp vec2 v_texCoordOut;
#endif

#ifdef COLOR
attribute vec4 a_color;
varying vec4 v_color;
#endif

#ifdef NORMAL
attribute vec3 a_normal;

uniform mat3 u_normalMat;
uniform vec3 u_lightDir;
uniform vec3 u_dirColor;
uniform vec3 u_ambient;
varying vec3 v_lightFilter;
#endif

#ifdef DISTORTION
uniform vec3 u_distortionPoint;
uniform float u_distortionFactor;
#endif

#ifdef BEZIER
uniform vec2 u_p1;
uniform vec2 u_p2;
uniform vec2 u_p3;
vec2 QuadraticBezierPoint(float pos)
{
    vec2 p1 = u_p1, p2 = u_p2, p3 = u_p3;
    
    vec2 P12 = (p2-p1)*pos,
         P23 = (p3-p2)*pos;
    
    return (((p2+P23)-(p1+P12))*pos) + p1 + P12;
}
#endif
uniform mat4 u_pvm;

void main()
{
    vec3 pos = a_position.xyz;

#ifdef TEXTURE
    v_texCoordOut = a_uv;
#endif
    
#ifdef COLOR
    v_color = a_color;
#endif
    
#ifdef NORMAL
    vec3 transformedNormal = u_normalMat * a_normal;
    float directionalLightWeighting = max(dot(transformedNormal, u_lightDir), 0.0);
    v_lightFilter = u_ambient + u_dirColor * directionalLightWeighting;
#endif
    
#ifdef BEZIER
    vec2 posxy = a_position.xy;
    if( posxy.x >= u_p1.x && posxy.x <= u_p3.x  )
         pos = vec3( QuadraticBezierPoint( posxy.x ), pos.y );
    else
        pos = vec3(u_p1,pos.z);
#endif

#ifdef DISTORTION
    /*
    float dist = sin(distance(pos,u_distortionPoint));
    pos += vec3(dist,dist,0) * u_distortionFactor;
    gl_Position = u_pvm * vec4( pos, a_position.w );
     */
    float maxDistance = 1.0;
    float length = clamp( abs(distance(pos.xyz,u_distortionPoint)), 0.0, maxDistance );
    float distortion = sin(length*5.0) * (maxDistance - length);
    gl_Position = u_pvm * vec4(pos*(1.0+distortion),a_position.w);
#else
	gl_Position   = u_pvm * vec4(pos,a_position.w);
#endif

}

