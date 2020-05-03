shader_type canvas_item;
render_mode unshaded;

uniform vec4 color1 : hint_color;
uniform vec4 replace_color1 : hint_color;

void fragment()
{
	vec4 pix_color = texture(TEXTURE, UV);
	if(pix_color == color1)
	{
		COLOR = replace_color1;
	}
	else
	{
		COLOR = pix_color;
	}
}