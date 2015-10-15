varying vec3 LightDir;
attribute vec3 tangent;
uniform vec3 lightdir;
varying vec3 tang;

void main() {
    gl_Position = ftransform(); 
	vec3 binormal = cross(tangent, gl_Normal);
    mat3 rotmat = mat3(tangent, binormal, gl_Normal);
    tang = tangent;
    LightDir = rotmat * normalize(lightdir);
   	LightDir = normalize(LightDir); 
    gl_TexCoord[0] = gl_MultiTexCoord0;
}
