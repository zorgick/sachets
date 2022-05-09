import * as React from "react";
import * as Server from "react-dom/server";
import { Button } from "@sachets/ui";

console.log(
  Server.renderToString(
    <Button onClick={() => console.log("hello")} label="Touch me" />
  )
);
