import 'dart:io';

import 'bean/method_parse.dart';
import 'platforms_source_gen.dart';
import 'bean/property_parse.dart';
import 'type_utils.dart';

enum ObjectivePropertType {
  base,
  systemClass,
  customClass,
  specialType,
}

class ObjectiveCCreate {
  static const Map<String, String> baseTypeMap = {
    "dart.core.bool": "BOOL",
    "dart.core.int": "int",
    "dart.core.double": "double",
  };
  static const Map<String, String> classTypeMap = {
    "dart.core.String": "NSString",
    "dart.typed_data.Uint8List": "NSArray",
    "dart.typed_data.Int32List": "NSArray",
    "dart.typed_data.Int64List": "NSArray",
    "dart.typed_data.Float64List": "NSArray",
    "dart.core.List": "NSArray",
    "dart.core.Map": "NSDictionary",
    "number": "NSNumber",
    "void": "void",
  };
  static const Map<String, String> specialTypeMap = {
    "dart.async.Future": "",
  };

  static var prefix = "";

  static void create(
      String projectPrefix, String savePath, List<GenClassBean> genClassBeans) {
    if (projectPrefix.isEmpty) {
      projectPrefix = "PSG"; // platforms source generator
    }
    createHeaderFile(projectPrefix, savePath, genClassBeans);
    createImplementFile(projectPrefix, savePath, genClassBeans);
  }

  static void createHeaderFile(
      String projectPrefix, String savePath, List<GenClassBean> genClassBeans) {
    Directory iosTargetDir = Directory(savePath);
    prefix = projectPrefix;
    bool exists = iosTargetDir.existsSync();
    if (!exists) {
      iosTargetDir.createSync(recursive: true);
    }
    genClassBeans.forEach((value) {
      File ocHeaderFile =
          File(savePath + "/" + projectPrefix + value.classInfo.name + ".h");
      //package
      String allContent = "";

      //import
      List<String> imports = [
        "#import <Foundation/Foundation.h>\n",
      ];
      String importStr = imports
          .toString()
          .replaceAll("[", "")
          .replaceAll("]", "")
          .replaceAll(",", "");

      allContent += "${importStr}";
      allContent += getCustomClassImport(value.properties);
      allContent += "\nNS_ASSUME_NONNULL_BEGIN\n";

      //property
      String propertyStr = property(value.properties);

      //method
      String methodStr = method(value.methods);

      String defineString = "\n";
      String defineSuffixString = "";
      if (haveAbstractMethods(value)) {
        defineString += "@protocol";
        defineSuffixString = "<NSObject>\n@optional";
      } else {
        defineString += "@interface";
        defineSuffixString = ": NSObject";
      }
      allContent += "${defineString} ${projectPrefix}${value.classInfo.name}";
      allContent +=
          " $defineSuffixString\n\n$propertyStr\n${methodStr}\n@end\nNS_ASSUME_NONNULL_END";
      ocHeaderFile.writeAsStringSync(allContent);
      if (!ocHeaderFile.existsSync()) {
        //if not create use dart io, use shell
        _savePath(allContent, ocHeaderFile.path);
      }
    });
  }

  static void createImplementFile(
      String projectPrefix, String savePath, List<GenClassBean> genClassBeans) {
    genClassBeans.forEach((value) {
      if (!haveAbstractMethods(value)) {
        File ocImplementFile =
            File(savePath + "/" + projectPrefix + value.classInfo.name + ".m");
        //package
        String className = "${projectPrefix}${value.classInfo.name}";
        String allContent = "#import \"$className.h\"\n";
        allContent += "\nNS_ASSUME_NONNULL_BEGIN\n";
        allContent += "@implementation $className";

        //property
        allContent += propertyImplementation(value.properties);

        //method
        allContent += methodImplementation(value.methods);

        allContent += "\n@end\nNS_ASSUME_NONNULL_END";
        ocImplementFile.writeAsStringSync(allContent);
        if (!ocImplementFile.existsSync()) {
          //if not create use dart io, use shell
          _savePath(allContent, ocImplementFile.path);
        }
      }
    });
  }

  /// create property
  static String property(List<Property> properties) {
    String propertyStr = "";
    properties.forEach((property) {
      String typeStr = getPropertyStr(property);
      String name = property.name;
      propertyStr += "$typeStr$name;\n";
    });
    return propertyStr;
  }

  /// create method
  static String method(List<MethodInfo> methods) {
    String result = "";
    methods.forEach((method) {
      result += "- (" + getTypeString(method.returnType) + ")" + method.name;
      String argType = "";
      if (!method.args.isEmpty) {
        result += ":";
        for (var i = 0; i < method.args.length; i++) {
          Property arg = method.args[i];
          if (i > 0) {
            argType += " ${arg.name}:";
          }
          argType += "(";
          if (arg.canBeNull && typeOf(arg) != ObjectivePropertType.base) {
            argType += "nullable ";
          }
          argType += getTypeString(arg) + ")" + arg.name;
        }
      }
      result += "$argType;\n";
    });
    return result;
  }

  static bool haveAbstractMethods(GenClassBean classBean) {
    return classBean.methods.isNotEmpty;
  }

  static String propertyImplementation(List<Property> properties) {
    String propertyStr =
        "\n- (instancetype)init\n{\n\tself = [super init];\n\tif (self) {\n";
    properties.forEach((property) {
      String name = property.name;
      String defaultValue = property.defaultValue1;
      if (defaultValue == "null") {
        defaultValue = "";
      }
      if (defaultValue.isNotEmpty) {
        propertyStr += "\t\tself.$name = ";
        if (property.type == "dart.core.String") {
          defaultValue = "@\"$defaultValue\"";
        } else if (property.type == "dart.typed_data.Uint8List" ||
            property.type == "dart.typed_data.Int32List" ||
            property.type == "dart.typed_data.Int64List" ||
            property.type == "dart.typed_data.Float64List" ||
            property.type == "dart.core.List") {
          defaultValue = defaultValue.replaceAll('[', '').replaceAll(']', '');
          if (defaultValue.isEmpty) {
            defaultValue = "[NSArray array]";
          } else {
            List<String> arguments = defaultValue.split(", ");
            arguments = convertObjcDefaultValueFor(
                arguments, typeOf(property.subType.first));
            defaultValue =
                "[NSArray arrayWithObjects:${arguments.join(", ")}, nil]";
          }
        } else if (property.type == "dart.core.Map") {
          defaultValue = defaultValue.replaceAll("{", "").replaceAll("}", "");
          if (defaultValue.isEmpty) {
            defaultValue = "[NSDictionary dictionary]";
          } else {
            List<String> arguments = defaultValue.split(", ");
            Map<String, String> map = Map.fromIterable(arguments,
                key: ((e) => converObjecDefaultValueFor(
                    e.substring(0, e.indexOf(":")),
                    typeOf(property.subType.first))),
                value: ((e) => converObjecDefaultValueFor(
                    e.substring(e.indexOf(":") + 2),
                    typeOf(property.subType.last))));
            defaultValue = "@$map";
          }
        }
        propertyStr += "$defaultValue;\n";
      }
    });
    propertyStr += "\n\t}\n\treturn self;\n}\n";
    return propertyStr;
  }

  static String converObjecDefaultValueFor(
      String propertyString, ObjectivePropertType type) {
    return convertObjcDefaultValueFor([propertyString], type).first;
  }

  static List<String> convertObjcDefaultValueFor(
      List<String> propertiesString, ObjectivePropertType type) {
    List<String> arguments = [];
    switch (type) {
      case ObjectivePropertType.base:
        arguments = List.from(propertiesString.map((e) => "@" + e));
        break;
      case ObjectivePropertType.systemClass:
        // all convert to NSString
        arguments = List.from(propertiesString.map((e) => "@\"$e\""));
        break;
      case ObjectivePropertType.customClass:
        arguments = List.from(propertiesString.map((e) =>
            "${e.replaceAll("Instance of '", "[$prefix").replaceAll("'", " new]")}"));
        break;
      default:
    }
    return arguments;
  }

  static String methodImplementation(List<MethodInfo> methods) {
    String result = "\n";
    methods.forEach((method) {
      result += "- (" + getTypeString(method.returnType) + ")" + method.name;
      String argType = "";
      if (!method.args.isEmpty) {
        method.args.forEach((arg) {
          argType += getTypeString(arg) + arg.name + ", ";
        });
        if (argType.endsWith(", ")) {
          //remove ", " ,because java method arg can't end with ", "
          argType = argType.substring(0, argType.length - 2);
        }
        result += "(" + argType + ")";
      }
      result += " {}\n";
    });
    return result;
  }

  static String getCustomClassImport(List<Property> properties) {
    String importString = "";
    Set<String> customClassTypes = Set();
    properties.forEach((value) {
      String typeString = getTypeString(value);
      typeString = typeString.replaceAll(" *", "");
      typeString = typeString.replaceAll("<", ", ");
      typeString = typeString.replaceAll(">", "");
      customClassTypes.addAll(typeString.split(", "));
    });
    customClassTypes.forEach((element) {
      if (element.startsWith(prefix)) {
        importString += "#import \"$element.h\"\n";
      }
    });
    return importString;
  }

  /// cover dart type to objc type
  static String getPropertyStr(
    Property property, {
    bool showNullTag = true,
  }) {
    String propertyString = "@property (nonatomic, ";
    switch (typeOf(property)) {
      case ObjectivePropertType.base:
        var baseType = baseTypeMap[property.type];
        propertyString += "assign) " + baseType! + " ";
        break;
      case ObjectivePropertType.systemClass:
        var classType = classTypeMap[property.type];
        propertyString += "strong";
        if (showNullTag && propertyString != "void") {
          propertyString +=
              (property.canBeNull ? ", nullable) " : ") ") + classType!;
        }
        if (property.subType.isNotEmpty) {
          propertyString += getSubTypeString(property);
        }
        propertyString += " *";
        break;
      case ObjectivePropertType.customClass:
        propertyString += "strong";
        propertyString += (property.canBeNull ? ", nullable) " : ") ") +
            "$prefix${property.type.split(".").last} *";
        break;
      default:
    }
    return propertyString;
  }

  static String getSubTypeString(Property property,
      {bool showNullTag = false}) {
    String subTypeString = "";
    subTypeString += "<";
    property.subType.forEach((element) {
      subTypeString += getTypeString(element, convertToClass: true);
      if (showNullTag &&
          element.canBeNull &&
          typeOf(element) != ObjectivePropertType.base) {
        subTypeString += " _Nullable";
      }
      subTypeString += ", ";
    });
    if (subTypeString.endsWith(", ")) {
      subTypeString = subTypeString.substring(0, subTypeString.length - 2);
    }
    subTypeString += ">";
    return subTypeString;
  }

  static ObjectivePropertType typeOf(Property property) {
    if (baseTypeMap.keys.contains(property.type)) {
      return ObjectivePropertType.base;
    } else if (classTypeMap.keys.contains(property.type)) {
      return ObjectivePropertType.systemClass;
    } else if (specialTypeMap.keys.contains(property.type)) {
      return ObjectivePropertType.specialType;
    } else {
      return ObjectivePropertType.customClass;
    }
  }

  static String getTypeString(Property property,
      {bool convertToClass = false}) {
    String typeString = "";
    switch (typeOf(property)) {
      case ObjectivePropertType.base:
        var baseType = baseTypeMap[property.type];
        if (convertToClass) {
          typeString += "NSNumber *";
        } else {
          typeString += "$baseType ";
        }
        break;
      case ObjectivePropertType.systemClass:
        var classType = classTypeMap[property.type];
        if (classType!.isNotEmpty) {
          typeString += "$classType";
        }
        if (property.subType.isNotEmpty) {
          String subTypeString = getSubTypeString(property);
          typeString += subTypeString;
        }
        typeString += " *";
        break;
      case ObjectivePropertType.specialType:
        typeString = getTypeString(property.subType.first);
        break;
      default:
        typeString += "$prefix${property.type.split(".").last}";
        if (property.subType.isNotEmpty) {
          String subTypeString = getSubTypeString(property, showNullTag: true);
          typeString += subTypeString;
        }
        typeString += " *";
    }
    return typeString;
  }

  /// save all content use shell
  static void _savePath(String content, String path) async {
    ProcessResult a = await Process.run('bash',
        ['-c', "echo '${content.replaceAll("'", "\'\"\'\"\'")}' >> $path"],
        runInShell: true);
    print("file: $path \n create result: ${a.exitCode}");
  }
}
