//
//  MeshScene+Emitter.m
//  TimbreGroove
//
//  Created by victor on 4/4/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "MeshScene.h"
#import "Log.h"
#import "Painter.h"

typedef struct _StrideTypeMap {
    VertexStrideType t;
    const char * name;
} StrideTypeMap;

static NSString * stringFromMat(GLKMatrix4 m)
{
    return [NSString stringWithFormat:@"{ %G, %G, %G, %G,   %G, %G, %G, %G,   %G, %G, %G, %G,   %G, %G, %G, %G }",
            m.m[0], m.m[1], m.m[2],  m.m[3],  m.m[4],  m.m[5],  m.m[6],  m.m[7],
            m.m[8], m.m[9], m.m[10], m.m[11], m.m[12], m.m[13], m.m[14], m.m[15] ];
}

@implementation MeshScene (Emitter)

-(void)emitSkin:(MeshSkinning *)skin
{
#if 0
    unsigned int   currPos  = 0;
    int            ji       = 0;
    int            wi;
    float          weight;
    
    NSArray * jointNames = [skin->_influencingJoints map:^id(MeshSceneArmatureNode * joint) {
        return joint->_name;
    }];
    
    TGLogp(LLMeshImporter, @"{ ");
    
    for( int i = 0; i < skin->_numInfluencingJointCounts; i++ )
    {
        int numberOfJointsApplied = skin->_influencingJointCounts[ i ];
        
        for( unsigned int n = 0; n < numberOfJointsApplied; n++  )
        {
            ji = skin->_packedWeightIndices[ currPos + skin->_jointWOffset ];
            wi = skin->_packedWeightIndices[ currPos + skin->_weightFOffset];
            currPos += 2;
            weight = skin->_weights[ wi ];
            char comma = (i+1 == skin->_numInfluencingJointCounts) && (n+1 == numberOfJointsApplied) ? ' ' : ',';
            TGLogp(LLMeshImporter, @"  %.4f%c // [%02d][%d] %@", weight, comma, i, n, jointNames[ji]);
        }
    }
#endif
    TGLogp(LLMeshImporter, @"};\n");
    
}
-(void)emit
{
    NSString * baseName = self.fileName;

    TGLogp(LLMeshImporter, @"// Imported COLLADA: %@",baseName);
    TGLogp(LLMeshImporter, @"#ifndef  %@_import_included",baseName);
    TGLogp(LLMeshImporter, @"#define  %@_import_included\n",baseName);

    printf("#ifndef  joint_import_struct_defined\n");
    printf("#define  joint_import_struct_defined\n");
    printf("typedef struct _Joint {\n  const char *name;\n  GLKVector3 startingPos;\n  GLKMatrix4 transform;\n  GLKMatrix4 invBind;\n  GLKMatrix4 world;\n} Joint;\n");
    printf("#endif\n\n");
    
    NSMutableArray * allJointNames = [NSMutableArray new];
    
    static void (^dumpBones)(id,MeshSceneArmatureNode *) = nil;
    
    dumpBones = ^(id key, MeshSceneArmatureNode * node) {
        
        [allJointNames addObject:node->_name];
        
        GLKVector3 vec3 = POSITION_FROM_MAT(node->_world);
        TGLogp(LLMeshImporter, @"Joint %@_%@_joint = {", baseName, node->_name);
        TGLogp(LLMeshImporter, @"  \"%@\",", node->_name);
        TGLogp(LLMeshImporter, @"  %@,", NSStringFromGLKVector3(vec3));

        TGLogp(LLMeshImporter, @"  %@,", stringFromMat(node->_transform));
        TGLogp(LLMeshImporter, @"  %@,", stringFromMat(node->_invBindMatrix));
        TGLogp(LLMeshImporter, @"  %@",  stringFromMat(node->_world));
        
        TGLogp(LLMeshImporter, @"};\n");
        
        if( node->_children )
            [node->_children each:dumpBones];
    };
    
    printf("#pragma mark BONES\n\n");
    
    [_joints each:^(id sender) { dumpBones(nil,sender); }];
    
    dumpBones = nil;
    
    NSUInteger totalNames = [allJointNames count];
    TGLogp(LLMeshImporter, @"Joint * %@_joints[%d] = {", baseName, totalNames);
    int nCount = 0;
    for( NSString * name in allJointNames )
    {
        TGLogp(LLMeshImporter, @"  &%@_%@_joint%s", baseName,name,++nCount == totalNames ? "" : ",");
    }
    TGLogp(LLMeshImporter, @"};\n");

    printf("#pragma mark GEOMETRY \n\n");

    static const char * gvs[] = {
        "gv_pos", "gv_normal", "gv_uv", "gv_acolor", "gv_boneIndex", "gv_boneWeights"
    };
    __block int meshCount = 0;
    [_meshes each:^(MeshSceneMeshNode * msmn) {
        [msmn->_geometries each:^(MeshGeometry *mg) {
            TGLogp(LLMeshImporter, @"VertexStride  _%@_%@_strides_%d[] = { ", baseName, mg->_name, meshCount);
            for( int i = 0; i < mg->_numStrides; i++ )
            {
                VertexStride * vs = &mg->_strides[ i ];
                printf( "  /* %s */\n  { .glType = GL_FLOAT, .numSize = sizeof(float), .numbersPerElement = %d\n",
                       gvs[vs->indexIntoShaderNames],
                       vs->numbersPerElement  );
                printf( "     .strideType = -1, .indexIntoShaderNames = %d }%s\n ",
                       vs->indexIntoShaderNames,
                       i == mg->_numStrides - 1 ? "" : ",");
            }
            printf( "  };\n");
            TGLogp(LLMeshImporter, @"float _%@_%@_buffer_%d[] = { ", baseName, mg->_name, meshCount);
            float * p = mg->_buffer;
            for( int v = 0; v < mg->_numVertices; v++ )
            {
                for( int i = 0; i < mg->_numStrides; i++ )
                {
                    VertexStride * vs = &mg->_strides[ i ];
                    for( int s = 0; s < vs->numbersPerElement; s++ )
                        printf( "%G, ", *p++ );
                    printf("  ");
                }
                printf("\n");
            }
            printf( "  };\n");
            ++meshCount;
        }];
    }];
    

    return;
    
    
    printf("#pragma mark SKIN\n\n");

    [_meshes each:^(MeshSceneMeshNode * mesh) {
        MeshSkinning * skin = mesh->_skin;
        if( skin )
        {
            TGLogp(LLMeshImporter, @"GLKMatrix4 %@_%@_bindShapeMatrix = %@;\n",
                   baseName, mesh->_name, stringFromMat(skin->_bindShapeMatrix));
            TGLogp(LLMeshImporter, @"float %@_weights[] = ",baseName);
            [self emitSkin:skin];
        }
    }];
    
    if( _animations )
    {
        printf("#pragma mark ANIMATION\n\n");
        
        int count = 0;
        for( MeshAnimation * animation in _animations )
        {
            TGLogp(LLMeshImporter,@"GLKMatrix4 %@_%@_animationFrames[] = { ", baseName, animation->_target->_name);
            
            for( int i = 0; i < animation->_numFrames; i++ )
            {
                TGLogp(LLMeshImporter,@"%@%s // Frame[%d] at %fsec",
                       stringFromMat(animation->_transforms[i]),
                       i + 1 < animation->_numFrames ? "," : "",
                       i, animation->_keyFrames[i] );
            }
            TGLogp(LLMeshImporter,@"\n}; // end %@_%@_animationFrames\n", baseName, animation->_target->_name);
            ++count;
        };
        
        int acount = 0;
        TGLogp(LLMeshImporter, @"GLKMatrix4 * %@_animation[] = { \n", baseName);
        for( MeshAnimation * animation in _animations )
        {
            ++acount;
            TGLogp(LLMeshImporter,@"   %@_%@_animationFrames%s", baseName, animation->_target->_name, acount == count ? "" : ",");
        }
        TGLogp(LLMeshImporter, @"};\n");
    }
    
    [_meshes each:^(MeshSceneMeshNode * mesh ) {
#if 0
        MeshGeometry_OLD * geometry = mesh->_geometry;
        NSString * meshName = mesh->_name;
        
        TGLogp(LLMeshImporter,@"#pragma mark GEOMETRY %@\n\n",meshName);
        
        for( int b = 0; b < kNumMeshSemanticKeys; b ++ )
        {
            MeshGeometryBuffer * bufferInfo = geometry->_buffers + b;
            if( !bufferInfo->data )
                continue;
            
            TGLogp(LLMeshImporter, @"GLKVector%d %@_%@_%s[%d] = {",
                   bufferInfo->stride,
                   baseName,
                   meshName,
                   varname[indexIntoNamesMap[b]],
                   bufferInfo->numFloats/bufferInfo->stride);
            
            float *p = bufferInfo->data;
            int count = bufferInfo->numFloats;
            for( int i = 0; i < count;  )
            {
                for( int r = 0; r < 3 && i < count; r++  )
                {
                    printf("{");
                    char * comma = "";
                    for( int s = 0; s < bufferInfo->stride; s++ )
                    { printf( "%s %+.3f ",comma, p[i++]); comma = ","; }
                    if( i + 1 < count )
                        printf("}, ");
                    else
                        printf("}");
                }
                printf("\n");
            }
            printf("};\n");
        }
        
        for( int ii = 0; ii < geometry->_numIndexBuffers; ii++ )
        {
            MeshGeometryIndexBuffer * bufferInfo = geometry->_indexBuffers + ii;
            if( bufferInfo->indexData )
            {
                TGLogp(LLMeshImporter, @"unsigned int %@_%@_%s_index_%d[%d] = {",
                       baseName,
                       meshName,
                       varname[indexIntoNamesMap[MSKPosition]],
                       ii,
                       bufferInfo->numIndices );
                
                unsigned int *p = bufferInfo->indexData;
                int count = bufferInfo->numIndices;
                int i;
                for( i = 0; i < count;  )
                {
                    for( int r = 0; r < 3 && i < count; r++  )
                    {
                        printf(" ");
                        char * comma = "";
                        for( int s = 0; s < 3; s++ )
                        {
                            printf( "%s %d",comma,p[i++]);
                            comma = ",";
                        }
                        if( i + 1 < count )
                            printf(", ");
                    }
                    printf("\n");
                }
                printf("};\n");
            }
            
        }
#endif
        
    }];
    
    TGLogp(LLMeshImporter, @"#endif // %@_import_included",baseName);
    
}
@end
