import path from 'node:path';
import _ from 'lodash';
import { Diagram, DiagramCircle, DiagramEdge, DiagramItem, DiagramSection } from './utils/diagrams';

(async () => {
    // Items

    const personalDevices = new DiagramItem('personal-devices.png', 'Personal\nDevices', { x: 100, y: 350 });
    const monikaDevices = new DiagramItem('personal-devices.png', "Monika's\nDevices", { x: personalDevices.coordinates.minX, y: 550 });

    const unbound1Default = new DiagramItem('unbound.png', 'Unbound\n1 Default', { x: personalDevices.coordinates.minX + 200, y: 150 });
    const unbound1Open = new DiagramItem('unbound.png', 'Unbound\n1 Open', { x: personalDevices.coordinates.minX + 200, y: 300 });
    const unbound2Default = new DiagramItem('unbound.png', 'Unbound\n2 Default', { x: personalDevices.coordinates.minX + 200, y: 600 });
    const unbound2Open = new DiagramItem('unbound.png', 'Unbound\n2 Open', { x: personalDevices.coordinates.minX + 200, y: 750 });

    const pihole1Primary = new DiagramItem('pihole.png', 'PiHole\n1 Primary', { x: unbound1Default.coordinates.minX + 300, y: unbound1Default.coordinates.minY });
    const pihole1Secondary = new DiagramItem('pihole.png', 'PiHole\n1 Secondary', { x: pihole1Primary.coordinates.minX, y: unbound1Open.coordinates.minY });
    const pihole2Primary = new DiagramItem('pihole.png', 'PiHole\n2 Primary', { x: pihole1Primary.coordinates.minX, y: unbound2Default.coordinates.minY });
    const pihole2Secondary = new DiagramItem('pihole.png', 'PiHole\n2 Secondary', { x: pihole1Primary.coordinates.minX, y: unbound2Open.coordinates.minY });

    const dns1 = new DiagramItem('cloud.png', 'Google\nDNS\n8.8.8.8', { x: pihole1Primary.coordinates.minX + 250, y: personalDevices.coordinates.minY });
    const dns2 = new DiagramItem('cloud.png', 'Cloudflare\nDNS\n1.1.1.1', { x: dns1.coordinates.minX, y: monikaDevices.coordinates.minY });

    const edgeIntersection1 = new DiagramCircle({ x: _.mean([unbound1Default.coordinates.maxX, pihole1Primary.coordinates.minX]) - 10, y: 500 - 10 }, { width: 20, height: 20 });
    const edgeIntersection2 = new DiagramCircle({ x: _.mean([pihole1Primary.coordinates.maxX, dns1.coordinates.minX]) + 10, y: 500 - 10 }, { width: 20, height: 20 });

    // Edges

    const defaultEdgeOffset = 20;
    for (const unbound of [unbound1Default, unbound2Default]) {
        new DiagramEdge({ node: personalDevices, location: 'right', offset: { x: defaultEdgeOffset, y: 0 } }, { node: unbound, location: 'left', offset: { x: -defaultEdgeOffset, y: 0 } });
    }
    for (const unbound of [unbound1Open, unbound2Open]) {
        new DiagramEdge({ node: monikaDevices, location: 'right', offset: { x: defaultEdgeOffset, y: 0 } }, { node: unbound, location: 'left', offset: { x: -defaultEdgeOffset, y: 0 } });
    }
    for (const unbound of [unbound1Default, unbound1Open, unbound2Default, unbound2Open]) {
        new DiagramEdge({ node: unbound, location: 'right', offset: { x: defaultEdgeOffset, y: 0 } }, { node: edgeIntersection1, location: 'left', connector: 'none', offset: { x: -defaultEdgeOffset, y: 0 } });
    }
    for (const pihole of [pihole1Primary, pihole1Secondary, pihole2Primary, pihole2Secondary]) {
        new DiagramEdge({ node: edgeIntersection1, location: 'right', offset: { x: defaultEdgeOffset, y: 0 } }, { node: pihole, location: 'left', offset: { x: -defaultEdgeOffset, y: 0 } });
        new DiagramEdge({ node: pihole, location: 'right', offset: { x: defaultEdgeOffset, y: 0 } }, { node: edgeIntersection2, location: 'left', connector: 'none', offset: { x: -defaultEdgeOffset, y: 0 } });
    }
    for (const dns of [dns1, dns2]) {
        new DiagramEdge({ node: edgeIntersection2, location: 'right', offset: { x: 20, y: 0 } }, { node: dns, location: 'left', offset: { x: -20, y: 0 } });
    }

    // Sections

    const sectionPadding = 50;
    new DiagramSection('Odroid H4 Ultra', { x: unbound1Default.coordinates.minX - sectionPadding, y: unbound1Default.coordinates.minY - sectionPadding }, { x: pihole1Primary.coordinates.maxX + sectionPadding, y: pihole1Secondary.coordinates.maxY + sectionPadding });
    new DiagramSection('Raspberry Pi 4B 4GB', { x: unbound2Default.coordinates.minX - sectionPadding, y: unbound2Default.coordinates.minY - sectionPadding }, { x: pihole2Primary.coordinates.maxX + sectionPadding, y: pihole2Secondary.coordinates.maxY + sectionPadding  });

    // Final

    Diagram.instance.writeToFile(path.join('src', 'dns.drawio'));
})();
