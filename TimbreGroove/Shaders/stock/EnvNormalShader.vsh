//
//  EnvNormalShader.vsh
//  created with Shaderific
//


attribute vec4 position;
attribute vec3 normal;
attribute vec2 texture;

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;

varying vec3 normalVarying; 
varying vec2 textureCoordinate;
varying vec4 eyespacePosition;


void main(void)
{
    
    normalVarying =  normal;
    textureCoordinate = texture;
    
    eyespacePosition = modelViewMatrix * position;
    gl_Position = modelViewProjectionMatrix * position;
    
}