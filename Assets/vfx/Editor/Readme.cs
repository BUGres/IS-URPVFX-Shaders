using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;
using System.IO;
using System.Reflection;

[CreateAssetMenu(fileName = "Readme", menuName = "Scriptable Objects/Readme")]
public class Readme : ScriptableObject
{
    
}

[CustomEditor(typeof(Readme))]
public class ReadmeEditor : Editor
{
    private bool isedit = false;
	public override void OnInspectorGUI()
    {
        GUIStyle astyle = new GUIStyle();
        astyle.fontSize = 32;
        astyle.normal.textColor = Color.yellow;
        GUIStyle style = new GUIStyle();
        style.fontSize = 16;
        style.normal.textColor = Color.yellow;
        
        GUILayout.Label("特效包说明", astyle);
        GUILayout.Label("此项目为开源项目\n此工程仅供测试\n" +
                        "如果需要在自己的工程部署本项目\n" +
                        "推荐访问获取Github页面的最新版本Release\n" +
                        "Release中的UnityPackage只包含重要代码\n" +
                        "去除了所有用于展示的内容\n" +
                        "下面是Github网址，你可以访问下面的网页\n" +
                        "", style);
        if (GUILayout.Button("访问提供此特效包的网站"))
        {
            Application.OpenURL("https://github.com/BUGres/IS-URPVFX-Shaders");
        }
    }
}
