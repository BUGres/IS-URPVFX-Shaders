using UnityEngine;
using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEngine.Rendering;
using UnityEngine.UI;

public class VFXShaderUnity : BaseShaderGUI
{
    private MaterialProperty[] properties;
    private Dictionary<string, MaterialProperty> propDict = new Dictionary<string, MaterialProperty>();
    private MaterialHeaderScopeList renderModeList = new MaterialHeaderScopeList(uint.MaxValue & ~(uint)Expandable.Advanced);

    private void GUIProperty(string name)
    {
        if (propDict.ContainsKey(name))
        {
            GUIProperty(propDict[name]);
        }
        else
        {
            GUILayout.Label("[TA修复]失效的MaterialPropertyName:" + name);
        }
    }

    private void GUIProperty(MaterialProperty prop)
    {
        if ((prop.flags & MaterialProperty.PropFlags.HideInInspector) == 0)
            materialEditor.ShaderProperty(EditorGUILayout.GetControlRect(true, 
                    materialEditor.GetPropertyHeight(prop, prop.displayName), 
                    EditorStyles.layerMaskField), 
                prop, prop.displayName);
    }

    private void GUIGroup(uint materialHeaderIndex, Action<Material> Func, Material material, string name)
    {
        renderModeList.RegisterHeaderScope(new GUIContent(name), materialHeaderIndex++, Func);
    }

    public override void OnGUI(MaterialEditor materialEditorIn, MaterialProperty[] propertiesIn)
    {
        materialEditor = materialEditorIn;
        properties = propertiesIn;
        propDict.Clear();
        foreach (var prop in properties)
        {
            // if (prop.type == MaterialProperty.PropType.Texture)
            // {
            //     materialEditor.PropertiesDefaultGUI(new MaterialProperty[] { prop });
            // }
            //
            // GUILayout.Label(prop.name);
            
            propDict.Add(prop.name, prop);
        }

        // litProperties = new LitGUI.LitProperties(properties);
        // litDetailProperties = new LitDetailGUI.LitProperties(properties);
        Material material = materialEditor.target as Material;
     
        GUIStyle titleStyle = new GUIStyle(GUI.skin.label);
        titleStyle.fontSize = 20;
        titleStyle.fontStyle = FontStyle.Bold;
        
        GUILayout.Label("特效大一统Shader", titleStyle);
        GUILayout.Label("");
        GUILayout.Label("此Shader主要供特效使用，支持CBuffer的SRPBatcher，希望同时兼顾优化和特效使用体验");
        GUILayout.TextArea("Github地址https://github.com/BUGres/IS-URPVFX-Shaders");
        GUILayout.Label("");

        #region 分组
        // 必要Group索引
        renderModeList = new MaterialHeaderScopeList(uint.MaxValue & ~(uint)Expandable.Advanced);
        #region 渲染模式组

        GUIGroup(1 << 0, material =>
        {
            GUILayout.Space(10);
            GUILayout.Label("渲染模式");
            int rq = material.renderQueue;
            int rendertype = material.GetInt("_RenderType");
            
            rendertype = EditorGUILayout.Popup(rendertype, new[]
            {
                "自定义模式(特效不推荐使用此模式，需要了解原理)",
                "传统透明度AlphaTest(特效常用的传统透明度，作为特效渲染)", 
                "传统透明度Transparent(特效常用的传统透明度，作为透明体渲染)", 
                "Add透明度AlphaTest(特效常用的Add颜色叠加，作为特效渲染)",
                "Add透明度Transparent(特效常用的Add颜色叠加，作为透明体渲染)", 
                "RT输入的虚拟透明模式(扭曲屏幕已有内容(自备RenderTexture))"
            });
            
            material.SetInt("_RenderType", rendertype);

            if (rendertype == 0)
            {
                // AlphaToMask
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("AlphaToMask");
                int selectAlphaToMask = material.GetInt("_AlphaToMask");
                int save_selectAlphaToMask = selectAlphaToMask;
                selectAlphaToMask = EditorGUILayout.Popup(selectAlphaToMask, new[] { "Off", "On" });
                if (save_selectAlphaToMask != selectAlphaToMask) material.SetInt("_AlphaToMask", selectAlphaToMask);
                GUILayout.EndHorizontal();
                GUILayout.BeginHorizontal();
                float Cutoff = material.GetFloat("_Cutoff");
                GUILayout.Label("Cutoff", GUILayout.Width(100));
                Cutoff = GUILayout.HorizontalSlider(Cutoff, 0, 1, GUILayout.Width(100));
                Cutoff = EditorGUILayout.FloatField(Cutoff, GUILayout.Width(100));
                material.SetFloat("_Cutoff", Cutoff);
                GUILayout.EndHorizontal();
                
                // Blend
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("Blend");
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
                
                // ColorMask
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("ColorMask");
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
                
                // Conservative
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("Conservative");
                int selectConservative = material.GetInt("_Conservative");
                int save_selectConservative = selectConservative;
                selectConservative = EditorGUILayout.Popup(selectConservative, new[] { "On (Default)", "Off" });
                if (save_selectConservative != selectConservative) material.SetInt("_Conservative", selectConservative);
                GUILayout.EndHorizontal();
                
                // Cull
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("Cull");
                int selectCull = material.GetInt("_Cull");
                int save_selectCull = selectCull;
                selectCull = EditorGUILayout.Popup(selectCull, new[] { "Off", "Front", "Back (Default)" });
                if (save_selectCull != selectCull) material.SetInt("_Cull", selectCull);
                GUILayout.EndHorizontal();
                
                // Offset
                GUILayout.Space(10);
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
                
                // ZClop
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("ZClip");
                int selectZClip = material.GetInt("_ZClip");
                selectZClip = EditorGUILayout.Popup(selectZClip, new[] { "Off", "On (Default)" });
                material.SetInt("_ZClip", selectZClip);
                GUILayout.EndHorizontal();
        
                // ZWrite
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("ZWrite");
                int selectZWrite = material.GetInt("_ZWrite");
                selectZWrite = EditorGUILayout.Popup(selectZWrite, new[] { "Off", "On (Default)" });
                material.SetInt("_ZWrite", selectZWrite);
                GUILayout.EndHorizontal();

                materialEditor.RenderQueueField();
                
                GUILayout.Label("贴图混合最终颜色的叠加模式");
                GUIProperty("_MixedColorAsAlpha");
            }
            else if (rendertype == 1)
            {
                material.SetFloat("_Cutoff", 0.5f);
                material.SetFloat("_AlphaToMask", 0);
                material.SetFloat("_SRGB", 5);
                material.SetFloat("_DRGB", 10);
                material.SetFloat("_SA", 0);
                material.SetFloat("_DA", 0);
                material.SetFloat("_ColorMask", 15);
                material.SetFloat("_Conservative", 0);
                // Cull
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("渲染剔除");
                int selectCull = material.GetInt("_Cull");
                int save_selectCull = selectCull;
                selectCull = EditorGUILayout.Popup(selectCull, new[] { "双面都渲染(特效常用)", "正面不渲染", "背面不渲染(Default)" });
                if (save_selectCull != selectCull) material.SetInt("_Cull", selectCull);
                GUILayout.EndHorizontal();
                material.SetFloat("_OffsetFactor", 0);
                material.SetFloat("_OffsetUnits", 0);
                material.SetFloat("_ZClip", 1);
                // ZWrite
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("深度写入");
                int selectZWrite = material.GetInt("_ZWrite");
                selectZWrite = EditorGUILayout.Popup(selectZWrite, new[] { "关闭(常用)", "开启(Default)" });
                material.SetInt("_ZWrite", selectZWrite);
                GUILayout.EndHorizontal();
                material.SetInt("_MixedColorAsAlpha", 1);
                material.renderQueue = 2450;
            }
            else if (rendertype == 2)
            {
                material.SetFloat("_Cutoff", 0.5f);
                material.SetFloat("_AlphaToMask", 0);
                material.SetFloat("_SRGB", 5);
                material.SetFloat("_DRGB", 10);
                material.SetFloat("_SA", 0);
                material.SetFloat("_DA", 0);
                material.SetFloat("_ColorMask", 15);
                material.SetFloat("_Conservative", 0);
                // Cull
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("Cull");
                int selectCull = material.GetInt("_Cull");
                int save_selectCull = selectCull;
                selectCull = EditorGUILayout.Popup(selectCull, new[] { "双面都渲染(特效常用)", "正面不渲染", "背面不渲染(Default)" });
                if (save_selectCull != selectCull) material.SetInt("_Cull", selectCull);
                GUILayout.EndHorizontal();
                material.SetFloat("_OffsetFactor", 0);
                material.SetFloat("_OffsetUnits", 0);
                material.SetFloat("_ZClip", 1);
                // ZWrite
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("深度写入");
                int selectZWrite = material.GetInt("_ZWrite");
                selectZWrite = EditorGUILayout.Popup(selectZWrite, new[] { "关闭(常用)", "开启(Default)" });
                material.SetInt("_ZWrite", selectZWrite);
                GUILayout.EndHorizontal();
                material.SetInt("_MixedColorAsAlpha", 1);
                material.renderQueue = 3000;
            }
            else if (rendertype == 3)
            {
                material.SetFloat("_Cutoff", 0.5f);
                material.SetFloat("_AlphaToMask", 0);
                material.SetFloat("_SRGB", 1);
                material.SetFloat("_DRGB", 1);
                material.SetFloat("_SA", 0);
                material.SetFloat("_DA", 0);
                material.SetFloat("_ColorMask", 15);
                material.SetFloat("_Conservative", 0);
                // Cull
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("Cull");
                int selectCull = material.GetInt("_Cull");
                int save_selectCull = selectCull;
                selectCull = EditorGUILayout.Popup(selectCull, new[] { "双面都渲染(特效常用)", "正面不渲染", "背面不渲染(Default)" });
                if (save_selectCull != selectCull) material.SetInt("_Cull", selectCull);
                GUILayout.EndHorizontal();
                material.SetFloat("_OffsetFactor", 0);
                material.SetFloat("_OffsetUnits", 0);
                material.SetFloat("_ZClip", 1);
                // ZWrite
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("深度写入");
                int selectZWrite = material.GetInt("_ZWrite");
                selectZWrite = EditorGUILayout.Popup(selectZWrite, new[] { "关闭(常用)", "开启(Default)" });
                material.SetInt("_ZWrite", selectZWrite);
                GUILayout.EndHorizontal();
                material.SetInt("_MixedColorAsAlpha", 0);
                material.renderQueue = 2450;
            }
            else if (rendertype == 4)
            {
                material.SetFloat("_Cutoff", 0.5f);
                material.SetFloat("_AlphaToMask", 0);
                material.SetFloat("_SRGB", 1);
                material.SetFloat("_DRGB", 1);
                material.SetFloat("_SA", 0);
                material.SetFloat("_DA", 0);
                material.SetFloat("_ColorMask", 15);
                material.SetFloat("_Conservative", 0);
                // Cull
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("Cull");
                int selectCull = material.GetInt("_Cull");
                int save_selectCull = selectCull;
                selectCull = EditorGUILayout.Popup(selectCull, new[] { "双面都渲染(特效常用)", "正面不渲染", "背面不渲染(Default)" });
                if (save_selectCull != selectCull) material.SetInt("_Cull", selectCull);
                GUILayout.EndHorizontal();
                material.SetFloat("_OffsetFactor", 0);
                material.SetFloat("_OffsetUnits", 0);
                material.SetFloat("_ZClip", 1);
                // ZWrite
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("深度写入");
                int selectZWrite = material.GetInt("_ZWrite");
                selectZWrite = EditorGUILayout.Popup(selectZWrite, new[] { "关闭(常用)", "开启(Default)" });
                material.SetInt("_ZWrite", selectZWrite);
                GUILayout.EndHorizontal();
                material.SetInt("_MixedColorAsAlpha", 0);
                material.renderQueue = 3000;
            }
            else if (rendertype == 5)
            {
                material.SetFloat("_Cutoff", 0.5f);
                material.SetFloat("_AlphaToMask", 0);
                material.SetFloat("_SRGB", 1);
                material.SetFloat("_DRGB", 0);
                material.SetFloat("_SA", 0);
                material.SetFloat("_DA", 0);
                material.SetFloat("_ColorMask", 15);
                material.SetFloat("_Conservative", 0);
                // Cull
                GUILayout.Space(10);
                GUILayout.BeginHorizontal();
                GUILayout.Label("Cull");
                int selectCull = material.GetInt("_Cull");
                int save_selectCull = selectCull;
                selectCull = EditorGUILayout.Popup(selectCull, new[] { "双面都渲染(特效常用)", "正面不渲染", "背面不渲染(Default)" });
                if (save_selectCull != selectCull) material.SetInt("_Cull", selectCull);
                GUILayout.EndHorizontal();
                material.SetFloat("_OffsetFactor", 0);
                material.SetFloat("_OffsetUnits", 0);
                material.SetFloat("_ZClip", 1);
                material.SetInt("_ZWrite", 0);
                material.SetInt("_MixedColorAsAlpha", 0);
                material.renderQueue = 2000;
            }
            else
            {
                GUILayout.Space(10);
                GUILayout.TextArea("使用了没有代码支持RenderType，这可能是这些代码还未完成，请选择其他RenderType");
            }

        }, material, "渲染模式(必要步骤)");

        #endregion
        #region 主贴图传递组

        GUIGroup(1 << 1, material =>
        {
            GUIProperty("_TextureI");
            GUIProperty("_EnableTextureIAlpha");
            GUIProperty("_TextureIFlow");
            GUIProperty("_TextureIFit");
            
            GUILayout.Label("___________________________________________________________________________");
            GUILayout.Space(10);
            GUILayout.BeginHorizontal();
            GUILayout.Label("贴图I与贴图II的叠加方式");
            int blendtype_I_II = material.GetInt("_BlendI_II");
            blendtype_I_II = EditorGUILayout.Popup(blendtype_I_II, new[] { "乘法叠加(default)", "加法叠加", "取Max", "取Min" });
            material.SetInt("_BlendI_II", blendtype_I_II);
            GUILayout.EndHorizontal();
            GUILayout.Label("___________________________________________________________________________");
            GUILayout.Space(10);
            
            GUIProperty("_TextureII");
            GUIProperty("_EnableTextureIIAlpha");
            GUIProperty("_TextureIIFlow");
            GUIProperty("_TextureIIFit");
            
            GUILayout.Label("___________________________________________________________________________");
            GUILayout.Space(10);
            
            GUIProperty("_TextureIII");
            GUIProperty("_EnableTextureIIIAlpha");

            GUILayout.Label("___________________________________________________________________________");
            GUILayout.Space(10);
            
            GUILayout.Label("颜色");
            if (material.GetInt("_RenderType") == 5)
            {
                GUILayout.TextArea("！！！\n注意：因为当前渲染模式为Rt模式，下面的主帖图需要为全屏幕的RenderTexture，" +
                                   "如果你不希望使用RenderTexture资产，而是改为内置RenderTexture输入，需要修改渲染管线\n！！！");
            }
            GUIProperty("_MainTexture");
            GUIProperty("_MainCol");
            GUIProperty("_EnableVertexColor");
            
            GUILayout.Label("___________________________________________________________________________");
            GUILayout.Space(10);
            GUILayout.TextArea("这里是最重要的组，大部分工作都在这里完成，在主帖图传递组中，大一统Shader的数字都使用罗马数字，用以和用户常用的阿拉伯数字区分," +
                               "贴图I 贴图II 贴图III 生成了一个混合结果，如果没有指定用法，这个混合结果就作为遮罩，给主帖图使用");
        }, material, "叠加贴图(必要步骤)");

        #endregion
        #region 溶解

        GUIGroup(1 << 2, material =>
        {
            GUILayout.TextArea("常用的溶解功能，此功能不使用时需要关闭");
            GUIProperty("_Dissolve");
            
            int dissolvetype = material.GetInt("_DissolveType");
            dissolvetype = EditorGUILayout.Popup(dissolvetype, new[]
            {
                "经典软溶解，不推荐(2-dissolve-alpha)",
                "硬溶解模式(stepalpha)", 
                "软溶解，从当前效果开始(alpha-dissolve)", 
            });
            material.SetInt("_DissolveType", dissolvetype);
            
            GUIProperty("_DissolveState");
            
        }, material, "溶解");

        #endregion
        #region UV扭曲

        GUIGroup(1 << 3, material =>
        {
            GUILayout.TextArea("UV扭曲采样程序噪声，不需要提供贴图，不用时请关闭");
            
            GUIProperty("_UVNoise");
            GUIProperty("_UVNoiseScale");
            GUIProperty("_UVNoiseWeight");
            GUIProperty("_UVNoiseTimeScale");
            
        }, material, "UV扭曲");

        #endregion
        #region UV扭曲

        GUIGroup(1 << 4, material =>
        {
            GUILayout.TextArea("菲涅尔效果，不用请关闭");
            
            GUIProperty("_NDV");
            GUIProperty("_NDVCol");
            GUIProperty("_NDVPow");
            GUIProperty("_NDVMul");
        }, material, "菲涅尔");

        #endregion
        
        #region TA调试

        GUIGroup(1 << 8, material =>
        {
            GUILayout.BeginHorizontal();
            GUILayout.Label("关键字");
            if (GUILayout.Button("清理所有材质球关键字"))
            {
                var klis = material.shaderKeywords;
                foreach (var klisitem in klis)
                {
                    material.DisableKeyword(klisitem);
                }
            }
            GUILayout.EndHorizontal();
            foreach (var keyword in material.shaderKeywords)
            {
                GUILayout.Label("MaterialKeyword:" + keyword);
            }
            foreach (var keyword in material.shader.keywordSpace.keywordNames)
            {
                GUILayout.Label("ShaderKeywordName:" + keyword);
            }

        }, material, "TA调试(仅供此Shader和Material调试)");

        #endregion
        renderModeList.DrawHeaders(materialEditor, material);
        #endregion
        
        // MaterialHeaderScopeList list2 = new MaterialHeaderScopeList(uint.MaxValue & ~(uint)Expandable.Advanced);
        // list2.RegisterHeaderScope(Styles.SurfaceOptions, (uint)2, DrawSurfaceOptions);
        // list2.DrawHeaders(materialEditor, material);
    }
}
