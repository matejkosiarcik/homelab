import { faker } from '@faker-js/faker';
import fs from 'node:fs';
import path from 'node:path';
import * as XML from 'fast-xml-parser';

interface DiagramElement {
    render(): string;
}

export type Point = { x: number; y: number };
export type Size = { width: number; height: number };
export type Rect = Point & Size;
export type OffsetSizeOrPosition = ({ width: number } | { x: number }) & ({ height: number} | { y: number });

export abstract class DiagramAbstractNode implements DiagramElement {
    readonly position: Point;
    readonly size: Size;
    readonly id: string;

    get rect(): Rect {
        return {
            x: this.position.x,
            y: this.position.y,
            width: this.size.width,
            height: this.size.height,
        };
    }

    get center(): Point {
        return {
            x: this.position.x + this.size.width / 2,
            y: this.position.y + this.size.height / 2,
        };
    }

    get coordinates(): { minX: number; minY: number; maxX: number; maxY: number; centerX: number; centerY: number } {
        return {
            minX: this.position.x,
            minY: this.position.y,
            maxX: this.position.x + this.size.width,
            maxY: this.position.y + this.size.height,
            centerX: this.position.x + this.size.width / 2,
            centerY: this.position.y + this.size.height / 2,
        };
    }

    constructor(position1: Point, position2: OffsetSizeOrPosition) {
        this.position = position1;
        this.size = { width: 0, height: 0 };
        if ('x' in position2 ) {
            this.size.width = position2.x - position1.x;
        } else if ('width' in position2) {
            this.size.width = position2.width;
        }
        if ('y' in position2 ) {
            this.size.height = position2.y - position1.y;
        } else if ('height' in position2) {
            this.size.height = position2.height;
        }
        this.id = faker.string.alpha(12);
        Diagram.instance.add(this);
    }

    render(): string {
        return '';
    }
}

export class DiagramItem extends DiagramAbstractNode {
    readonly image: string;
    readonly text: string;
    readonly ids: string[] = [];

    constructor(image: string, text: string, position: Point) {
        super(position, { width: 60, height: 100 });
        this.image = image;
        this.text = text;
        this.ids = [
            this.id,
            faker.string.alpha(12),
            faker.string.alpha(12),
            faker.string.alpha(12),
        ];
    }

    override render(): string {
        const imageBuffer = fs.readFileSync(path.join('icons', this.image));
        const imageText = `data:image/png,${imageBuffer.toString('base64')}`;

        return `
            <!-- Wrapper -->
            <mxCell id="${this.ids[0]}" value="" style="group;rounded=1;fillStyle=solid;align=center;verticalAlign=middle;fontFamily=Helvetica;fontSize=12;fontColor=#FFFFFF" connectable="0" vertex="1" parent="1">
                <mxGeometry x="${this.rect.x}" y="${this.rect.y}" width="${this.rect.width}" height="${this.rect.height}" as="geometry" />
            </mxCell>
            <!-- Background -->
            <mxCell id="${this.ids[1]}" value="" style="rounded=1;whiteSpace=wrap;html=1;strokeColor=none;fillColor=#19191F;fontColor=#FFFFFF;resizable=0;container=0;rotatable=0;movable=0;pointerEvents=0;align=center;verticalAlign=top;fontFamily=Helvetica;fontSize=12;fillStyle=solid;" vertex="1" parent="${this.ids[0]}">
                <mxGeometry x="0" y="0" width="${this.rect.width}" height="${this.rect.height}" as="geometry" />
            </mxCell>
            <!-- Image -->
            <mxCell id="${this.ids[2]}" value="" style="icon;html=1;image=${imageText};strokeColor=none;fillColor=none;rounded=0;resizable=0;movable=0;connectable=0;allowArrows=0;recursiveResize=1;expand=1;editable=1;rotatable=0;deletable=1;locked=0;part=0;pointerEvents=0;container=0;imageAlign=center;align=center;verticalAlign=top;fontFamily=Helvetica;fontSize=12;fontColor=default;fillStyle=solid;" vertex="1" parent="${this.ids[0]}">
                <mxGeometry x="0" y="0" width="${this.rect.width}" height="${this.rect.width}" as="geometry" />
            </mxCell>
            <!-- Text -->
            <mxCell id="${this.ids[3]}" value="&lt;span&gt;&lt;font style=&quot;color: rgb(255, 255, 255);&quot;&gt;${this.text.replaceAll('\n', '&lt;br/&gt;')}&lt;/font&gt;&lt;/span&gt;" style="text;html=1;align=center;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=10;fontColor=#FFFFFF;resizable=0;container=0;rotatable=0;connectable=0;pointerEvents=0;movable=0;allowArrows=0;imageAlign=center;fontFamily=Helvetica;" vertex="1" parent="${this.ids[0]}">
                <mxGeometry x="0" y="${this.rect.width}" width="${this.rect.width}" height="${this.rect.height - this.rect.width}" as="geometry" />
            </mxCell>
        `;
    }
}

export class DiagramSection extends DiagramAbstractNode {
    readonly text: string;
    readonly ids: string[] = [];

    constructor(text: string, position: Point, size: OffsetSizeOrPosition) {
        super(position, size);
        this.text = text;
        this.ids = [
            this.id,
            faker.string.alpha(12),
            faker.string.alpha(12),
        ];
    }

    override render(): string {
        return `
            <mxCell id="${this.ids[0]}" value="" style="group" vertex="1" connectable="0" parent="1">
                <mxGeometry x="${this.position.x}" y="${this.position.y}" width="${this.size.width}" height="${this.size.height}" as="geometry" />
            </mxCell>
            <mxCell id="${this.ids[1]}" value="" style="rounded=1;whiteSpace=wrap;html=1;fillColor=none;dashed=1;dashPattern=8 8;strokeColor=#FFFFFF;" parent="${this.ids[0]}" vertex="1">
                <mxGeometry x="0" y="0" width="${this.size.width}" height="${this.size.height}" as="geometry" />
            </mxCell>
            <mxCell id="${this.ids[2]}" value="${this.text.replaceAll('\n', '&lt;br/&gt;')}" style="text;html=1;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontColor=#FFFFFF" parent="${this.ids[0]}" vertex="1">
                <mxGeometry x="${Math.floor(this.size.width / 12)}" y="0" width="${Math.floor(this.size.width / 2)}" height="30" as="geometry" />
            </mxCell>
        `;
    }
}

export class DiagramCircle extends DiagramAbstractNode {
    override render(): string {
        return `
            <mxCell id="${this.id}" value="" style="ellipse;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=none;" vertex="1" parent="1">
                <mxGeometry x="${this.position.x}" y="${this.position.y}" width="${this.size.width}" height="${this.size.height}" as="geometry" />
            </mxCell>
        `;
    }
}

export type DiagramEdgeLocation = 'top' | 'bottom' | 'left' | 'right';

export class DiagramEdge implements DiagramElement {
    readonly id: string;
    readonly points: Point[];
    readonly connectedIds: string[] = [];
    readonly connectors = {
        start: '',
        end: '',
    };

    constructor(start: { node: DiagramAbstractNode, location: DiagramEdgeLocation, offset?: Point | Point[] | undefined, connector?: 'none' | 'arrow' | undefined }, end:  { node: DiagramAbstractNode, location: DiagramEdgeLocation, offset?: Point | Point[] | undefined, connector?: 'none' | 'arrow' | undefined  }, midPoint?: Point | Point[] | undefined) {
        this.id = faker.string.alpha(12);
        const startPoint = (() => {
            switch (start.location) {
                case 'top': return { x: start.node.coordinates.centerX, y: start.node.coordinates.minY };
                case 'bottom': return { x: start.node.coordinates.centerX, y: start.node.coordinates.maxY };
                case 'left': return { x: start.node.coordinates.minX, y: start.node.coordinates.centerY };
                case 'right': return { x: start.node.coordinates.maxX, y: start.node.coordinates.centerY };
            }
        })();
        const startOffsetPoint = (() => {
            if (start.offset === undefined || (Array.isArray(start.offset) && start.offset.length === 0)) {
                return [];
            }
            return [start.offset].flat().map((el) => ({ x: startPoint.x + el.x, y: startPoint.y + el.y }));
        })();
        const endPoint = (() => {
            switch (end.location) {
                case 'top': return { x: end.node.coordinates.centerX, y: end.node.coordinates.minY };
                case 'bottom': return { x: end.node.coordinates.centerX, y: end.node.coordinates.maxY };
                case 'left': return { x: end.node.coordinates.minX, y: end.node.coordinates.centerY };
                case 'right': return { x: end.node.coordinates.maxX, y: end.node.coordinates.centerY };
            }
        })();
        const endOffsetPoint = (() => {
            if (end.offset === undefined || (Array.isArray(end.offset) && end.offset.length === 0)) {
                return [];
            }
            return [end.offset].flat().map((el) => ({ x: endPoint.x + el.x, y: endPoint.y + el.y }));
        })();
        const midPoints = (() => {
            if (midPoint === undefined || (Array.isArray(midPoint) && midPoint.length === 0)) {
                return [];
            }
            return [midPoint].flat();
        })();
        this.points = [
            startPoint,
            ...startOffsetPoint,
            ...midPoints,
            ...endOffsetPoint,
            endPoint,
        ];
        this.connectedIds = [start.node.id, end.node.id];
        this.connectors = {
            start: start.connector ?? 'none',
            end: end.connector ?? 'arrow',
        }
        Diagram.instance.add(this);
    }

    render(): string {
        const startConnector = (() => {
            switch (this.connectors.start) {
                case 'none': return 'startArrow=none;';
                case 'arrow': return 'startArrow=classic;';
                default: return '';
            }
        })();
        const endConnector = (() => {
            switch (this.connectors.end) {
                case 'none': return 'endArrow=none;';
                case 'arrow': return 'endArrow=classic;';
                default: return '';
            }
        })();
        return `
            <mxCell id="${this.id}" value="" style="${startConnector}${endConnector}html=1;rounded=1;strokeColor=#FFFFFF;" edge="1" parent="1" source="${this.connectedIds[0]}" target="${this.connectedIds[1]}">
                <mxGeometry width="0" height="0" relative="1" as="geometry">
                    <mxPoint x="${this.points[0].x}" y="${this.points[0].y}" as="sourcePoint" />
                    <mxPoint x="${this.points.at(-1)!.x}" y="${this.points.at(-1)!.y}" as="targetPoint" />
                    ${this.points.length > 2 ? '<Array as="points">' : ''}
                    ${this.points.slice(1, this.points.length - 1).map((el) => `<mxPoint x="${el.x}" y="${el.y}" />`).join('\n')}
                    ${this.points.length > 2 ? '</Array>' : ''}
                </mxGeometry>
            </mxCell>
        `;
    }
}

export class Diagram implements DiagramElement {
    static readonly instance: Diagram = new Diagram();

    private readonly elements: DiagramElement[] = [];

    add(element: DiagramElement) {
        this.elements.push(element);
    }

    render() {
        return `
            <mxfile host="" agent="" version="26.2.2">
                <diagram name="Diagram" id="${faker.string.alpha(12)}">
                    <mxGraphModel background="#2a2a2a" dx="0" dy="0" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="2000" pageHeight="1000" math="0" shadow="0">
                    <root>
                        <mxCell id="0" />
                        <mxCell id="1" parent="0" />
                        ${this.elements.map(node => node.render()).join('\n')}
                    </root>
                    </mxGraphModel>
                </diagram>
            </mxfile>
        `;
    }

    writeToFile(file: string) {
        const output = this.render();

        const xmlParser = new XML.XMLParser({
            ignoreAttributes: false,
        });
        const xmlObject = xmlParser.parse(output);
        const xmlBuilder = new XML.XMLBuilder({
            ignoreAttributes: false,
            format: true,
            indentBy: '  ',
        });
        const xmlOutput = xmlBuilder.build(xmlObject);
        fs.writeFileSync(file, xmlOutput, 'utf8');
    }
}
