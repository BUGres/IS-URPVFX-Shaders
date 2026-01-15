using UnityEngine;
using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEngine.Rendering;
using UnityEngine.UI;

public class SurfaceShaderUnity : BaseShaderGUI
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
        
        GUILayout.Label("表面复合Shader", titleStyle);
        GUILayout.Label("");
        GUILayout.Label("此Shader主要供模型渲染使用，支持CBuffer的SRPBatcher，希望同时兼顾优化和美术效果");
        // GUILayout.TextArea("Github地址https://github.com/BUGres/IS-URPVFX-Shaders");
        GUILayout.Label("");

        renderModeList = new MaterialHeaderScopeList(uint.MaxValue & ~(uint)Expandable.Advanced);
        GUIGroup(1 << 0, material =>
        {
            GUILayout.Space(10);
            GUILayout.Label("渲染模式");
            // int rq = material.renderQueue;
            // int rendertype = 1;
            //
            // rendertype = EditorGUILayout.Popup(rendertype, new[]
            // {
            //     "自定义模式(特效不推荐使用此模式，需要了解原理)",
            //     "传统透明度AlphaTest(特效常用的传统透明度，作为特效渲染)", 
            //     "传统透明度Transparent(特效常用的传统透明度，作为透明体渲染)", 
            //     "Add透明度AlphaTest(特效常用的Add颜色叠加，作为特效渲染)",
            //     "Add透明度Transparent(特效常用的Add颜色叠加，作为透明体渲染)", 
            //     "RT输入的虚拟透明模式(扭曲屏幕已有内容(自备RenderTexture))"
            // });
            
            // material.SetInt("_RenderType", rendertype);
        
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
        
        }, material, "渲染模式");
        
        // GUIGroup(2 << 0, material =>
        // {
        //     GUILayout.Space(10);
        // }, material, "PBR渲染");
        
        GUIGroup(1 << 2, material =>
        {
            GUILayout.Space(10);
            GUIProperty("_MainTex");
            GUIProperty("_MainCol");
        }, material, "基本属性");
        
        GUIGroup(1 << 3, material =>
        {
            GUILayout.Space(10);
            GUIProperty("_NPR");
        }, material, "NPR渲染");
        
        GUIGroup(1 << 4, material =>
        {
            GUILayout.Space(10);
            GUIProperty("_PBR");
            GUIProperty("_F0");
            GUIProperty("_F82");
            GUIProperty("_FakeIBL");
            GUIProperty("_HDRTex");
            GUIProperty("_RMOTex");
            GUIProperty("_RMO");
            GUIProperty("_Roughness");
            GUIProperty("_Metallic");
            GUIProperty("_AO");
            GUIProperty("_NormalTex");
            GUIProperty("_UseNormalTex");
            GUIProperty("_RealShadow");
            GUIProperty("_PBR_AL");
            GUIProperty("_PBR_AL_Diffuse");
            GUIProperty("_PBR_AL_Specular");
        }, material, "PBS渲染");
        
        GUIGroup(1 << 5, material =>
        {
            GUILayout.Space(10);
            GUIProperty("_KK");
            GUIProperty("_KKCol");
            GUIProperty("_KKMul");
            GUIProperty("_KKPow");
            GUIProperty("_FE");
            GUIProperty("_FECol");
            GUIProperty("_FEMul");
            GUIProperty("_FEPow");
        }, material, "特殊效果");
        
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
        
        }, material, "调试");
        
        renderModeList.DrawHeaders(materialEditor, material);
    }
}
