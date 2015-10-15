uniform sampler2D tex1;
uniform sampler2D tex2;
uniform vec2 offset;
void main(void)
{
    vec4 c;
    c = texture2D(tex1, gl_TexCoord[0].st);
    c+= texture2D(tex2, offset+gl_TexCoord[1].st);
    gl_FragColor = c / 2.0 ;
}
