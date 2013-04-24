//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
//
precision highp float;

attribute vec4 a_position;
uniform mat4 u_pvm;
uniform mat4 u_mvm;

#ifdef TEXTURE
attribute vec2 a_uv;
varying lowp vec2 v_texCoordOut;
#endif

#ifdef COLOR
attribute vec4 a_color;
varying vec4 v_vertex_color;
#endif

#ifdef BONES

uniform int  u_numJoints;
uniform mat4 u_jointMats[12];
uniform mat4 u_jointInvMats[12];

// ok, so this is not really a vec4, it's a variable array
// of floats and limits the number of influencing joints
// to 4 per pixel

attribute vec4 a_boneWeights;
attribute vec4 a_boneIndex;

vec4 doSkinning()
{
    if( u_numJoints == 0 )
        return a_position;
        
    vec4 pos = vec4( vec3(0.0), 1.0 );

    ivec4 index = ivec4(a_boneIndex);
    vec4  weights = a_boneWeights;
    
    for( int j = 0; j < 4; j++ )
    {
        float weight = weights[j];
        if( weight == 0.0 )
            break;
        
        pos += ((u_jointInvMats[index[j]] * vec4(a_position.xyz,1.0)) * u_jointMats[index[j]]) * weight;
    }

    return pos;
}
#endif

#ifdef NORMAL

#define NUM_LIGHTS 2

const int CI_Ambient  = 0;
const int CI_Diffuse  = 1;
const int CI_Specular = 2;
const int CI_Emission = 3;

const int CI_NUM_COLORS = 4;

struct Light {
	vec4   position;
    vec4   colors[CI_NUM_COLORS];
	vec3   attenuation;
    
	float spotCutoffAngle;
	vec3  spotDirection;
	float spotFalloffExponent;
};

attribute vec3 a_normal;

varying vec4   v_color;
varying vec4   v_specular;

uniform mat3   u_normalMat;
uniform int    u_lightsEnabled;
uniform Light  u_lights[NUM_LIGHTS];
uniform vec4   u_material[CI_NUM_COLORS];
uniform float  u_shininess;
uniform bool   u_doSpecular;

vec3 l_ecPosition3;
vec3 l_normal;
vec3 l_eye;
vec4 l_vertexPosition;
vec3 l_vertexNormal;


void pointLight(const in Light light,
				inout vec4 ambient,
				inout vec4 diffuse,
				inout vec4 specular)
{
	float nDotVP;
	float eDotRV;
	float pf;
	float attenuation;
	float d;
	vec3 VP;
	vec3 reflectVector;
    
	// 1 means light source is directional
    // 0 means ambient
	if (light.position.w == 0.0)
    {
		attenuation = 1.0;
		VP = light.position.xyz;
    }
    else
    {
        // Normalize the distance of the
		// Vector between light position and vertex
		VP = vec3(light.position.xyz - l_ecPosition3);
		d  = length(VP);
		VP = normalize(VP);

		// Calculate attenuation
		vec3 attDist = vec3(1.0, d, d * d);
		attenuation = 1.0 / dot(light.attenuation, attDist);
        
		// Calculate spot lighting effects
		if (light.spotCutoffAngle > 0.0) {
			float spotFactor = dot(-VP, light.spotDirection);
			if (spotFactor >= cos(radians(light.spotCutoffAngle))) {
				spotFactor = pow(spotFactor, light.spotFalloffExponent);
			} else {
				spotFactor = 0.0;
			}
			attenuation *= spotFactor;
		}
	}
    
	// angle between normal and light-vertex vector
	nDotVP = max(0.0, dot(VP, l_normal));
	
 	ambient += light.colors[CI_Ambient] * attenuation;
	if (nDotVP > 0.0) {
		diffuse += light.colors[CI_Diffuse] * (nDotVP * attenuation);
        
		if (u_doSpecular) {
			// reflected vector
			reflectVector = normalize(reflect(-VP, l_normal));
			
			// angle between eye and reflected vector
			eDotRV = max(0.0, dot(l_eye, reflectVector));
			eDotRV = pow(eDotRV, 16.0);
            
			pf = pow(eDotRV, u_shininess);
			specular += light.colors[CI_Specular] * (pf * attenuation);
		}
	}
}

void doLighting()
{
	vec4 amb = vec4(0.0);
	vec4 diff = vec4(0.0);
	vec4 spec = vec4(0.0);
    
	if( u_lightsEnabled > 0 )
    {
        mat3 normalMat = u_normalMat;
        
        normalMat = mat3( u_mvm );
        
		l_ecPosition3  = vec3(u_mvm * l_vertexPosition);
		l_eye          = -normalize(l_ecPosition3);
		l_normal       = normalize( normalMat * l_vertexNormal );
        
        for( int i = 0; i < u_lightsEnabled; i++ )
            pointLight( u_lights[i], amb, diff, spec );

		v_color.rgb = (u_material[CI_Ambient].rgb + amb.rgb) * u_material[CI_Ambient].rgb +
                      (diff.rgb * u_material[CI_Diffuse].rgb);
        
		v_color.a   = u_material[CI_Diffuse].a;
		
		v_color    = clamp(v_color, 0.0, 1.0);
		v_specular = vec4( spec.rgb * u_material[CI_Specular].rgb, u_material[CI_Specular].a );
        
	} else {
		v_color = u_material[CI_Diffuse];
		v_specular = spec;
	}
}

#endif

#ifdef TIME
uniform float u_time;
varying float v_time;
#endif

void main()
{
#ifdef TEXTURE
    v_texCoordOut = a_uv;
#endif
    
#ifdef COLOR
    v_vertex_color = a_color;
#endif
    
#ifdef NORMAL
    l_vertexPosition = a_position;
    l_vertexNormal = a_normal;
    doLighting();
#endif
    
#ifdef TIME
    v_time = u_time;
#endif

#ifdef BONES
    vec4 pos = doSkinning();
#else
    vec4 pos = a_position;
#endif

	gl_Position = u_pvm * pos;
}

