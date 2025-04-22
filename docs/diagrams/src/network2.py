from diagrams import Cluster, Diagram, Edge, Node
from diagrams.custom import Custom # type: ignore

icons_path = "../icons"
common_node_attributes = {
    "labelloc": "b",
    "width": "2",
    "height": "3",
    "fixedsize": "true",
    "imagescale": "true",
}

with Diagram("Homelab Network", show=False, filename="./out/network2"):
    internet = Custom("Internet", f"{icons_path}/cloud.png", **common_node_attributes)

    with Cluster("Living Room"):
        lte_modem = Custom("Huawei E3372", f"{icons_path}/usb-wifi.png", **common_node_attributes)
        router = Custom("TP-Link ER605", f"{icons_path}/router.png", **common_node_attributes)
        switch_8_dumb = Custom("Switch\nTP-Link SG108", f"{icons_path}/switch.png", **common_node_attributes)
        switch_8_smart = Custom("Switch\nTP-Link SG108E", f"{icons_path}/switch.png", **common_node_attributes)
        unifi_u6_mesh = Custom("WiFi AP\nUniFi U6 Mesh", f"{icons_path}/wifi-ap.png", **common_node_attributes)
        usb_ethernet_adapter = Custom("USB Ethernet adapter", f"{icons_path}/usb.png", **common_node_attributes)
        personal_notebook_1 = Custom("Personal Notebook", f"{icons_path}/notebook.png", **common_node_attributes)
        desklamp_1 = Custom("DeskLamp\nRaspberry Pi Pico", f"{icons_path}/lightbulb.png", **common_node_attributes)
        desklamp_2 = Custom("DeskLamp\nRaspberry Pi Pico", f"{icons_path}/lightbulb.png", **common_node_attributes)
        macbook_pro_2012 = Custom("Server\nMacBook Pro 2012", f"{icons_path}/notebook.png", **common_node_attributes)

        internet >> Edge() << lte_modem >> Edge() << router
        router >> Edge() << switch_8_dumb
        router >> Edge() << switch_8_smart
        switch_8_smart >> Edge() << unifi_u6_mesh
        switch_8_smart >> Edge() << usb_ethernet_adapter >> Edge() << personal_notebook_1
        switch_8_smart >> Edge() << desklamp_1
        switch_8_smart >> Edge() << desklamp_2
        switch_8_smart >> Edge() << macbook_pro_2012
        desklamp_1 - Edge(color="transparent") - desklamp_2 - Edge(color="transparent") - macbook_pro_2012 - Edge(color="transparent") - unifi_u6_mesh

        with Cluster("Rack"):
            odroid_h4_ultra = Custom("Server\nOdroid H4 Ultra", f"{icons_path}/server-big.png", **common_node_attributes)
            odroid_h3 = Custom("Server\nOdroid H3", f"{icons_path}/server-big.png", **common_node_attributes)
            raspberry_pi_4b_2gb = Custom("Server\nRaspberry Pi 4B 2GB", f"{icons_path}/server-small.png", **common_node_attributes)
            switch_unifi_2g_mini = Custom("Switch\nUniFi Flex 2.5G mini", f"{icons_path}/switch.png", **common_node_attributes)

            switch_8_smart >> Edge() << switch_unifi_2g_mini
            switch_unifi_2g_mini >> Edge() << odroid_h4_ultra
            switch_unifi_2g_mini >> Edge() << odroid_h3
            switch_unifi_2g_mini >> Edge() << raspberry_pi_4b_2gb
            odroid_h4_ultra - Edge(color="transparent") - odroid_h3 - Edge(color="transparent") - raspberry_pi_4b_2gb

    personal_devices = Custom("Personal Devices", f"{icons_path}/personal-devices.png", **common_node_attributes)
    unifi_u6_mesh >> Edge(style="dotted") << personal_devices

    with Cluster("Kitchen"):
        switch_5_smart = Custom("Switch\nTP-Link SG105E", f"{icons_path}/switch.png", **common_node_attributes)
        raspberry_pi_3b = Custom("Server\nRaspberry Pi 3B", f"{icons_path}/server-small.png", **common_node_attributes)
        raspberry_pi_3b_antenna = Custom("DVB-T Antenna", f"{icons_path}/antenna.png", **common_node_attributes)
        raspberry_pi_4b_4gb = Custom("Server\nRaspberry Pi 4B 4GB", f"{icons_path}/server-small.png", **common_node_attributes)
        webcamera = Custom("USB\nWebcam", f"{icons_path}/webcamera.png", **common_node_attributes)

        router >> Edge() << switch_5_smart
        switch_5_smart >> Edge() << raspberry_pi_3b << raspberry_pi_3b_antenna
        switch_5_smart >> Edge() << raspberry_pi_4b_4gb << webcamera
