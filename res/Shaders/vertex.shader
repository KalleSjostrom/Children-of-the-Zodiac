uniform float r;

void main(void)
{
    vec4 v = gl_Vertex;
    v.y += 0.3*cos(r+v.x);
    gl_Position = gl_ModelViewProjectionMatrix * v;    
    gl_TexCoord[0].xy = gl_Vertex.xy;
    gl_TexCoord[1].xy = gl_Vertex.xy;
}
