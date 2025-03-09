void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    float res = max(iResolution.x,iResolution.y);
    vec2 uv = (fragCoord - iResolution.xy / 2.0)/res;
    fragColor = vec4(sim_pixel(uv, vec2(1.0 / res,1.0 / res)),1.0);
}