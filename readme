# MCUI

## ComputerCraft UI Framework

Anyone who has tried to create an interactive program with ComputerCraft
knows the mess and confusion it creates in a program.
That's what inspired me to make this API.
MCUI is a flexible and easy to learn framework designed with the express purpsose of balancing adaptability to your UI needs and ease of use to create easy-on-the-eyes programs.

## Documentation

There are 5 main classes that are used in the MCUI framework. Instance, Device, Frame, Screen, and Visual Instances.
They're organized in a hierchy like this:

Instance -> Device -> Frame -> Screen -> Visual Instance

The method of organization is simple and intuitive.
All items are considered instances.
Devices will be the top of the chain used in programs, which represent the in-game object where everything is displayed. They can contain several frames in the form of tabs.
Each frame can be set to a variety of Screens,
and each Screen is composed of Visual Instances.

### Class 1: Instance

The base class is the Instance class. All other classes are children of this class, and will inheret its properties.
*All four of the other main classes are direct children of this class, and so inheret its properties*. You can't explicity create a new "Instance" object.
You can only create one of the classes four sub-classes
using the Instance.new() function.

| Property | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `parent` | `Instance` | The parent of the instance. Can be set with the :setParent method. |
| `children` | `Dictionary` | A dictionary containing the Instances children, with keys equal to the names of the children |
| `className` | `String` | **READ ONLY**. The type of Instance the object is. |
| `name` | `String` | **Required**. A unique identifier for the Instance. |

You can't create an Instance object in your programs, but you can create one of the other four sub-classes with the Instance.new() function. 

### Class 2: Device

The device is the highest up. It has 2 unique properties:
| Property | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `framerate` | `Integer` | The frames per second at which the device will display |
| `peripheral` | `Peripheral` | **READ ONLY** The reference to the in-game device  |

The framerate property is frames per second. 20 in the maximum, and setting the value any higher won't make it run faster
as ComputerCraft is limited by Minecraft's tick rate.
The peripheral property is the reference to the in-game device.
This value can't be written to, but can be set with the :wrap and :find methods (more on those in the API Reference).

### Class 3: Frame

The frame class is the third on the list.
They're displayed whenever they are a child to a Device class, and will show on whatever their current parents device is, whether that be the terminal or a monitor.

All of the integer based properties of the Frame class (and Visual Instance class) will always be integers,
but will update themselves responsively if you set them to a string such as "50%", "17%", etc.

This class has eight unique properties:
| Property | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `x` | `Integer` | The x coordinate |
| `y` | `Integer` | The y coordinate  |
| `z` | `Integer` | The z coordinate |
| `width` | `Integer` | The width  |
| `height` | `Integer` | The height |
| `draggable` | `Boolean` | Whether you can move the frame around  |
| `resizable` | `Boolean` | Whether you can resize the frame |
| `visible` | `Boolean` | If the frame should be displayed |

### Class 4: Screen

The screen class is fourth on the list. 
