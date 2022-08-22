//--------------------------------------------------------------------------------------
// File: BasicCompute11.hlsl
//
// This file contains the Compute Shader to perform array A + array B
// 
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License (MIT).
//--------------------------------------------------------------------------------------

struct BufType
{
    int i;
    int f;
#ifdef TEST_DOUBLE
    double d;
#endif    
};

#ifdef USE_STRUCTURED_BUFFERS

struct BufType
{
    int i;
    int f;
#ifdef TEST_DOUBLE
    double d;
#endif    
};

StructuredBuffer<BufType> Buffer0 : register(t0);
StructuredBuffer<BufType> Buffer1 : register(t1);
RWStructuredBuffer<BufType> BufferOut : register(u0);


groupshared int2 sharedData[1024];

[numthreads(256, 1, 1)]
void CSMain(uint3 DTid : SV_DispatchThreadID)
{
    BufferOut[DTid.x].i = Buffer0[DTid.x - 1].i + Buffer1[DTid.x + 1].i;
    BufferOut[DTid.x].f = Buffer0[DTid.x - 1].f + Buffer1[DTid.x + 1].f;
#ifdef TEST_DOUBLE
    BufferOut[DTid.x].d = Buffer0[DTid.x].d + Buffer1[DTid.x].d;
#endif 
}

#else // The following code is for raw buffers
groupshared int2 sharedData[128];

ByteAddressBuffer Buffer0 : register(t0);
ByteAddressBuffer Buffer1 : register(t1);
RWByteAddressBuffer BufferOut : register(u0);

[numthreads(256, 1, 1)]
void CSMain(uint3 DTid : SV_DispatchThreadID, uint3 GTid : SV_GroupThreadID)
{
    if (GTid.x < 128) {
        sharedData[GTid.x] = int4(2 * DTid.x + 1, 2 * DTid.x + 2, 0, 0);
    }
    GroupMemoryBarrierWithGroupSync();
#ifdef TEST_DOUBLE
    int i0 = asint(Buffer0.Load(DTid.x * 16));
    float f0 = asfloat(Buffer0.Load(DTid.x * 16 + 4));
    double d0 = asdouble(Buffer0.Load(DTid.x * 16 + 8), Buffer0.Load(DTid.x * 16 + 12));
    int i1 = asint(Buffer1.Load(DTid.x * 16));
    float f1 = asfloat(Buffer1.Load(DTid.x * 16 + 4));
    double d1 = asdouble(Buffer1.Load(DTid.x * 16 + 8), Buffer1.Load(DTid.x * 16 + 12));

    BufferOut.Store(DTid.x * 16, asuint(i0 + i1));
    BufferOut.Store(DTid.x * 16 + 4, asuint(f0 + f1));

    uint dl, dh;
    asuint(d0 + d1, dl, dh);

    BufferOut.Store(DTid.x * 16 + 8, dl);
    BufferOut.Store(DTid.x * 16 + 12, dh);
#else
    int i0 = asint(Buffer0.Load(DTid.x * 8 - 4));
    int i1 = asint(Buffer1.Load(DTid.x * 8 + 4));
    int f0 = sharedData[GTid.x - 0].y;
    int f1 = sharedData[GTid.x + 0].w;
    int f2 = sharedData[GTid.x - 0].z;
    int f3 = sharedData[GTid.x + 1].x;
    //int f0 = asint(Buffer0.Load(DTid.x * 8));
    //int f1 = asint(Buffer1.Load(DTid.x * 8));
    GroupMemoryBarrierWithGroupSync();

    BufferOut.Store(DTid.x * 8, asuint(i0 + i1));
    BufferOut.Store(DTid.x * 8 + 4, asuint(f0 + f1 + f2 + f3));
#endif // TEST_DOUBLE
}

#endif // USE_STRUCTURED_BUFFERS
