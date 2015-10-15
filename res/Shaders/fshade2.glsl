uniform sampler2D colorMap; //The texture
uniform sampler2D normalMap; //The bump-map 
varying vec3 LightDir; //Receiving the transformed light direction 
varying vec3 tang; //Receiving the transformed light direction 

void main() {
    vec3 BumpNorm = vec3(texture2D(normalMap, gl_TexCoord[0].xy));
    vec4 bumpTest = texture2D(normalMap, gl_TexCoord[0].xy);
    vec4 DecalCol = texture2D(colorMap, gl_TexCoord[0].xy);
    BumpNorm = (BumpNorm - 0.5) * 2.0;
    float NdotL = max(dot(BumpNorm, LightDir), 0.0);
    vec4 diffuse = NdotL * DecalCol;
    gl_FragColor = diffuse; // vec4(tang, 1);
}
