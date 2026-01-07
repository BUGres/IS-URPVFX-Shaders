using UnityEngine;
using UnityEditor;

public class vfx_shader_dissolve : VFXShaderBase
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        GUIStyle titleStyle = new GUIStyle(GUI.skin.label);
        titleStyle.fontSize = 20;
        titleStyle.fontStyle = FontStyle.Bold;
        GUILayout.Label("溶解", titleStyle);
        base.OnGUI(materialEditor, properties);
        GUILayout.TextArea("常规溶解");
    }
}

// public class vfx_shader_dissolveHard : VFXShaderBase
// {
//     public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
//     {
//         GUIStyle titleStyle = new GUIStyle(GUI.skin.label);
//         titleStyle.fontSize = 20;
//         titleStyle.fontStyle = FontStyle.Bold;
//         GUILayout.Label("溶解", titleStyle);
//         base.OnGUI(materialEditor, properties);
//         GUILayout.TextArea("本shader没有渲染功能，只是一个拓展shader的案例，如果你准备按照格式增加shader，" +
//                            "可以阅读VFXShaderBase.cs文件中<vfx_shader_base>类，只需10余行就可以增加这样的GUI，" +
//                            "shader复制vfx_shader_base.shader文件，进行修改，这样你就得到了一个新的ShaderGUI类和一个新的shader");
//     }
// }

public class vfx_shader_tail : VFXShaderBase
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        GUIStyle titleStyle = new GUIStyle(GUI.skin.label);
        titleStyle.fontSize = 20;
        titleStyle.fontStyle = FontStyle.Bold;
        GUILayout.Label("拖尾(已弃用，要做拖尾用溶解即可)", titleStyle);
        base.OnGUI(materialEditor, properties);
        GUILayout.TextArea("shader复制vfx_shader_base.shader文件，进行修改，这样你就得到了一个新的ShaderGUI类和一个新的shader");
    }
}

public class vfx_shader_ground : VFXShaderBase
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        GUIStyle titleStyle = new GUIStyle(GUI.skin.label);
        titleStyle.fontSize = 20;
        titleStyle.fontStyle = FontStyle.Bold;
        GUILayout.Label("地面(已启用)", titleStyle);
        base.OnGUI(materialEditor, properties);
        GUILayout.TextArea("shader复制vfx_shader_base.shader文件，进行修改，这样你就得到了一个新的ShaderGUI类和一个新的shader");
    }
}

public class vfx_shader_inkwash : VFXShaderBase
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        GUIStyle titleStyle = new GUIStyle(GUI.skin.label);
        titleStyle.fontSize = 20;
        titleStyle.fontStyle = FontStyle.Bold;
        GUILayout.Label("水墨", titleStyle);
        base.OnGUI(materialEditor, properties);
        GUILayout.TextArea("只能用于Mesh，很简单的水墨效果");
    }
}

public class vfx_shader_inksprite : VFXShaderBase
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        GUIStyle titleStyle = new GUIStyle(GUI.skin.label);
        titleStyle.fontSize = 20;
        titleStyle.fontStyle = FontStyle.Bold;
        GUILayout.Label("水墨2D(已弃用)", titleStyle);
        base.OnGUI(materialEditor, properties);
        GUILayout.TextArea("水墨2D AlphaToMask 风格");
    }
}

public class vfx_shader_2d : VFXShaderBase
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        GUIStyle titleStyle = new GUIStyle(GUI.skin.label);
        titleStyle.fontSize = 20;
        titleStyle.fontStyle = FontStyle.Bold;
        GUILayout.Label("2D标准", titleStyle);
        base.OnGUI(materialEditor, properties);
        GUILayout.TextArea("2D标准shader是从3D简化而来的，简化了appdata/v2f结构，去掉了几何阶段geoshader，同时仍然开放了大部分渲染指令（gpu state commands），可用于粒子系统2d物体渲染");
    }
}

public class vfx_shader_shield : VFXShaderBase
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        GUIStyle titleStyle = new GUIStyle(GUI.skin.label);
        titleStyle.fontSize = 20;
        titleStyle.fontStyle = FontStyle.Bold;
        GUILayout.Label("护盾类型", titleStyle);
        base.OnGUI(materialEditor, properties);
        GUILayout.TextArea("推荐用于标准球形");
    }
}

public class vfx_shader_knife : VFXShaderBase
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        GUIStyle titleStyle = new GUIStyle(GUI.skin.label);
        titleStyle.fontSize = 20;
        titleStyle.fontStyle = FontStyle.Bold;
        GUILayout.Label("刀光类型", titleStyle);
        base.OnGUI(materialEditor, properties);
        GUILayout.TextArea("一般用于扇形");
    }
}

public class vfx_shader_vertexFire : VFXShaderBase
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        GUIStyle titleStyle = new GUIStyle(GUI.skin.label);
        titleStyle.fontSize = 20;
        titleStyle.fontStyle = FontStyle.Bold;
        GUILayout.Label("顶点火焰", titleStyle);
        base.OnGUI(materialEditor, properties);
        GUILayout.TextArea("用于模型顶点拓展火焰特效");
    }
}