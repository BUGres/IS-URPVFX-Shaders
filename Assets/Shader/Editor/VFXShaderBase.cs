using UnityEngine;
using UnityEditor;

public class vfx_shader_base : VFXShaderBase
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        GUIStyle titleStyle = new GUIStyle(GUI.skin.label);
        titleStyle.fontSize = 20;
        titleStyle.fontStyle = FontStyle.Bold;
        GUILayout.Label("标准vfxShader", titleStyle);
        base.OnGUI(materialEditor, properties);
        GUILayout.TextArea("本shader没有渲染功能，只是一个拓展shader的案例，如果你准备按照格式增加shader，" +
                        "可以阅读VFXShaderBase.cs文件中<vfx_shader_base>类，只需10余行就可以增加这样的GUI，" +
                        "shader复制vfx_shader_base.shader文件，进行修改，这样你就得到了一个新的ShaderGUI类和一个新的shader");
    }
}

public class VFXShaderBase : ShaderGUI
{
    private bool tog_showMoreInfo = false;
    
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        // base.OnGUI(materialEditor, properties);
        Material material = materialEditor.target as Material;

        GUIStyle titleStyle = new GUIStyle(GUI.skin.label);
        titleStyle.fontSize = 20;
        titleStyle.fontStyle = FontStyle.Bold;
        
        GUIStyle boldStyle = new GUIStyle(GUI.skin.label);
        boldStyle.fontStyle = FontStyle.Bold;
        
        GUIStyle shortStyle = new GUIStyle(GUI.skin.label);
        shortStyle.fontSize = 10;
        
        tog_showMoreInfo = GUILayout.Toggle(tog_showMoreInfo, "显示完整信息，适用于初次使用此shader");
        bool showinfo = tog_showMoreInfo;
        
        // 使用自定义样式创建标签
        GUILayout.Label("GPU渲染状态", titleStyle);
        if (showinfo) GUILayout.TextArea("ShaderLab - GPU render state commands \n" +
                                         "指令功能请参考官网文档\n" +
                                         "https://docs.unity3d.com/6000.0/Documentation/Manual/SL-Commands.html\n" +
                                         "另外补充微软DX12中类似的功能\n" +
                                         "https://learn.microsoft.com/en-us/windows/win32/direct3d12/managing-graphics-pipeline-state-in-direct3d-12");
        
        
        GUILayout.Label("");
        GUILayout.BeginHorizontal();
        GUILayout.Label("AlphaToMask", boldStyle);
        int selectAlphaToMask = material.GetInt("_AlphaToMask");
        int save_selectAlphaToMask = selectAlphaToMask;
        selectAlphaToMask = EditorGUILayout.Popup(selectAlphaToMask, new[] { "Off", "On" });
        if (save_selectAlphaToMask != selectAlphaToMask) material.SetInt("_AlphaToMask", selectAlphaToMask);
        GUILayout.EndHorizontal();
        if (showinfo) GUILayout.TextArea("在启用此参数前，必须了解AlphaToMask，从优化来说不建议AlphaToMask和Blend共同使用（除非不得已），AlphaToMask本身不支持半透明，只是按照Alpha剔除一些面");
        GUILayout.BeginHorizontal();
        float Cutoff = material.GetFloat("_Cutoff");
        GUILayout.Label("Cutoff", GUILayout.Width(100));
        Cutoff = GUILayout.HorizontalSlider(Cutoff, 0, 1, GUILayout.Width(100));
        Cutoff = EditorGUILayout.FloatField(Cutoff, GUILayout.Width(100));
        material.SetFloat("_Cutoff", Cutoff);
        GUILayout.EndHorizontal();
        if (showinfo) GUILayout.TextArea("此参数的值目前增加在Alpha上");
        
        
        
        // Blend <source factor RGB> <destination factor RGB>, <source factor alpha> <destination factor alpha>
        GUILayout.Label("");
        GUILayout.BeginHorizontal();
        GUILayout.Label("Blend", boldStyle);
        var aoptions = new[]
        {
            "Zero", "One", "DstColor", "SrcColor", "OneMinusDstColor", "SrcAlpha", "OneMinusSrcColor", "DstAlpha",
            "OneMinusDstAlpha", "SrcAlphaSaturate", "OneMinusSrcAlpha"
        };
        int selectSRGB = material.GetInt("_SRGB");
        selectSRGB = EditorGUILayout.Popup(selectSRGB, aoptions);
        material.SetInt("_SRGB", selectSRGB);
        
        int selectDRGB = material.GetInt("_DRGB");
        selectDRGB = EditorGUILayout.Popup(selectDRGB, aoptions);
        material.SetInt("_DRGB", selectDRGB);
        
        int selectSA = material.GetInt("_SA");
        selectSA = EditorGUILayout.Popup(selectSA, aoptions);
        material.SetInt("_SA", selectSA);
        
        int selectDA = material.GetInt("_DA");
        selectDA = EditorGUILayout.Popup(selectDA, aoptions);
        material.SetInt("_DA", selectDA);
        GUILayout.EndHorizontal();
        if (showinfo) GUILayout.TextArea("Blend <source factor RGB> <destination factor RGB>, <source factor alpha> <destination factor alpha> 分离了RGB和A，可以分别选择，参数参考如下" +
                                         "One 值为 1 - 让源或目标颜色通过。\n" +
                                         "Zero 值为 0 - 删除源或目标值。\n" +
                                         "SrcColor 此阶段的值乘以源颜色值。\n" +
                                         "SrcAlpha 此阶段的值乘以源 Alpha 值。\n" +
                                         "DstColor 此阶段的值乘以帧缓冲区源颜色值。\n" +
                                         "DstAlpha 此阶段的值乘以帧缓冲区源 Alpha 值。\n" +
                                         "OneMinusSrcColor 此阶段的值乘以（1 - 源颜色）。\n" +
                                         "OneMinusSrcAlpha 此阶段的值乘以（1 - 源 Alpha）。\n" +
                                         "OneMinusDstColor 此阶段的值乘以（1 - 目标颜色）。\n" +
                                         "OneMinusDstAlpha 此阶段的值乘以（1 - 目标 Alpha）。\n" +
                                         "下面是一些预设：" +
                                         "Blend SrcAlpha OneMinusSrcAlpha // 传统透明度\n" +
                                         "Blend One OneMinusSrcAlpha // 预乘透明度\n" +
                                         "Blend One One // 加法\n" +
                                         "Blend OneMinusDstColor One // 软加法\n" +
                                         "Blend DstColor Zero // 乘法\n" +
                                         "Blend DstColor SrcColor // 2x 乘法\n" +
                                         "上面这些Src是生成颜色，Dst是屏幕原始颜色，Blend One Zero 就可以理解为：放弃已有颜色，用我新算的颜色填充，就变成不透明了\n" +
                                         "这里A通道你会发现失效，这是因为颜色直接输出到帧缓冲，强制使alpha=1了，如果渲染到RT，A值就正常了，简单来说，如果shader直接在屏幕上渲染，就可以不管后两个参数随便填写即可");
        
        
        
        // UnityEngine.Rendering.ColorWriteMask
        GUILayout.Label("");
        GUILayout.BeginHorizontal();
        GUILayout.Label("ColorMask", boldStyle);
        int colormask = material.GetInt("_ColorMask");
        int save_colormask = colormask;
        bool colormaskR = (colormask & 8) != 0;
        bool colormaskG = (colormask & 4) != 0;
        bool colormaskB = (colormask & 2) != 0;
        bool colormaskA = (colormask & 1) != 0;
        colormaskR = GUILayout.Toggle(colormaskR, "R");
        colormaskG = GUILayout.Toggle(colormaskG, "G");
        colormaskB = GUILayout.Toggle(colormaskB, "B");
        colormaskA = GUILayout.Toggle(colormaskA, "A");
        colormask = (colormaskR ? 8 : 0) +
                    (colormaskG ? 4 : 0) +
                    (colormaskB ? 2 : 0) +
                    (colormaskA ? 1 : 0);
        if (save_colormask != colormask) material.SetInt("_ColorMask", colormask);
        GUILayout.EndHorizontal();
        if (showinfo) GUILayout.TextArea("控制GPU是否写入RGBA通道");
        // UnityEngine.Rendering.BlendMode
        
        
        
        GUILayout.Label("");
        GUILayout.BeginHorizontal();
        GUILayout.Label("Conservative", boldStyle);
        int selectConservative = material.GetInt("_Conservative");
        int save_selectConservative = selectConservative;
        selectConservative = EditorGUILayout.Popup(selectConservative, new[] { "On (Default)", "Off" });
        if (save_selectConservative != selectConservative) material.SetInt("_Conservative", selectConservative);
        GUILayout.EndHorizontal();
        if (showinfo) GUILayout.TextArea("开启保守光栅化，如果不理解什么是保守光栅化，推荐关掉");
        
        
        
        GUILayout.Label("");
        GUILayout.BeginHorizontal();
        GUILayout.Label("Cull", boldStyle);
        int selectCull = material.GetInt("_Cull");
        int save_selectCull = selectCull;
        selectCull = EditorGUILayout.Popup(selectCull, new[] { "Off", "Front", "Back (Default)" });
        if (save_selectCull != selectCull) material.SetInt("_Cull", selectCull);
        GUILayout.EndHorizontal();
        if (showinfo) GUILayout.TextArea("按照朝向剔除，如果想要双面渲染则关闭");
        
        
        
        GUILayout.Label("");
        GUILayout.Label("Offset", boldStyle);
        GUILayout.BeginHorizontal();
        float OffsetFactor = material.GetFloat("_OffsetFactor");
        GUILayout.Label("factor", GUILayout.Width(100));
        OffsetFactor = GUILayout.HorizontalSlider(OffsetFactor, -1, 1, GUILayout.Width(100));
        OffsetFactor = EditorGUILayout.FloatField(OffsetFactor, GUILayout.Width(100));
        material.SetFloat("_OffsetFactor", OffsetFactor);
        GUILayout.EndHorizontal();
        GUILayout.BeginHorizontal();
        float OffsetUnits = material.GetFloat("_OffsetUnits");
        GUILayout.Label("units", GUILayout.Width(100));
        OffsetUnits = GUILayout.HorizontalSlider(OffsetUnits, -1, 1, GUILayout.Width(100));
        OffsetUnits = EditorGUILayout.FloatField(OffsetUnits, GUILayout.Width(100));
        material.SetFloat("_OffsetUnits", OffsetUnits);
        GUILayout.EndHorizontal();
        if (showinfo) GUILayout.TextArea("深度便宜，默认都是0，负值更靠近摄像机");
        
        
        
        GUILayout.Label("");
        GUILayout.BeginHorizontal();
        GUILayout.Label("ZClip", boldStyle);
        int selectZClip = material.GetInt("_ZClip");
        selectZClip = EditorGUILayout.Popup(selectZClip, new[] { "Off", "On (Default)" });
        material.SetInt("_ZClip", selectZClip);
        GUILayout.EndHorizontal();
        if (showinfo) GUILayout.TextArea("深度裁剪，过于靠近或原理相机的点（片元着色器中）是否丢弃");
        
        GUILayout.Label("");
        GUILayout.BeginHorizontal();
        GUILayout.Label("ZWrite", boldStyle);
        int selectZWrite = material.GetInt("_ZWrite");
        selectZWrite = EditorGUILayout.Popup(selectZWrite, new[] { "Off", "On (Default)" });
        material.SetInt("_ZWrite", selectZWrite);
        GUILayout.EndHorizontal();
        if (showinfo) GUILayout.TextArea("深度写入，一般用于blend出问题的时候关闭");
        
        
        GUILayout.Label("输入", titleStyle);
        if (showinfo) GUILayout.TextArea("标准shader输入内容，包括主贴图，主颜色等");
        materialEditor.PropertiesDefaultGUI(properties);
        
        GUILayout.Label("说明", titleStyle);
    }
}
